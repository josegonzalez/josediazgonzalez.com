---
  title:       "Deploying our application"
  date:        2016-12-24 05:04
  description: "Part 24 of a series of posts that will help you build out a personal CMS"
  category:    cakephp
  tags:
    - deployment
    - heroku
    - cakeadvent-2016
    - cakephp
  comments:    true
  sharing:     true
  published:   true
  layout:      post
  disable_advertisement: true
  series:      CakeAdvent-2016
---

A friend of mine asked for a custom website, so here I am, writing a custom cms. I know, there are plenty of systems out there that would handle his needs, but it's also a good excuse to play around with CakePHP 3, so here we are.

> For the lazy, the codebase we'll be working on will be available on [GitHub](https://github.com/josegonzalez/cakeadvent-2016). I will be pushing each set of changes on the date when each blog post in this series is published. No cheating!

## Errata from previous post

Looks like I should run the code before committing it. Here are a few issues with the last post:

- The OrderNotificationBehavior was attached improperly. It should be as follows:

  ```php
  $this->addBehavior('PhotoPostType.OrderNotification');
  ```

- The namespace for `OrderNotificationBehavior` should be `namespace PhotoPostType\Model\Behavior;`.
- The `use` statement for `QueueTrait` should be `use Josegonzalez\CakeQueuesadilla\Traits\QueueTrait;`.
- Missing a comma on line 20 of `OrderNotificationBehavior`.
- Extra semicolon around line 34 of `OrderNotificationBehavior`
- Missing data from the `shipped` MailerJob enqueue in `OrderNotificationBehavior`. It should be:

  ```php
  'data' => [
      'order_id' => $entity->id
  ],
  ```

Thanks to those who've pointed out my derps. These fixes are available as the first commit in the current release.

## Creating a heroku application

First, you'll want to install the [heroku cli](https://devcenter.heroku.com/articles/heroku-cli). This will be used to orchestrate our application on heroku.

In the app repository, I ran the following to create a new heroku app:

```shell
heroku create
```

There is a bit of configuration we need to set in order to get our app fully working in heroku. First, lets ensure our `config/.env.default` does not override our environment variables by setting an application name:

```shell
heroku config:set APP_NAME=calico
```

Next, we'll disable debug, as otherwise deploying will have errors regarding DebugKit not being installed. On heroku, packages in our composer.json `require-dev` section are not installed, so skipping this will mean our `config/bootstrap.php` will attempt to load a non-existent plugin.

```shell
heroku config:set DEBUG=false
```

In order to send email, you'll probably want to configure your `EMAIL_TRANSPORT_DEFAULT_URL` env var as well. I've set mine to smtp settings from a Gmail account, though if you want to use a custom email transport for an email service, you are welcome to do that as well. Don't forget to set a primary email!

```shell
heroku config:set EMAIL_TRANSPORT_DEFAULT_URL="mail://user:secret@localhost:25/?client=null&timeout=30&tls=null"
heroku config:set PRIMARY_EMAIL="example@example.com"
```

We'll also want to configure stripe properly. I'll add the following to my `config/app.php` and `config/app.default.php`:

```php
/**
 * Configures Stripe
 */
'Stripe' => [
    'publishablekey' => env('STRIPE_PUBLISHABLEKEY', 'pk_test_1234'),
    'secretkey' => env('STRIPE_SECRETKEY', 'sk_test_abcd'),
    'mode' => env('STRIPE_MODE', 'test')
],

/**
 * Sets primary config for our app (email, etc.)
 */
'Primary' => [
    'email' => env('PRIMARY_EMAIL', 'example@example.com'),
],
```

And we can set the env vars like normal:

```shell
heroku config:set STRIPE_PUBLISHABLEKEY=pk_test_1234
heroku config:set STRIPE_SECRETKEY=sk_test_abcd
heroku config:set STRIPE_MODE=test
heroku config:set PRIMARY_EMAIL="example@example.com"
```

Commit!

```shell
git add config/app.default.php
git commit -m "Ensure we read env vars for stripe and primary email configuration"
```

I'll configure a database, queuing, and our cache layer using some heroku addons for postgres and redis:

```shell
heroku addons:create heroku-postgresql:hobby-dev
heroku addons:create heroku-redis:hobby-dev

APP_NAME="$(heroku config:get APP_NAME)"
DATABASE_URL="$(heroku config:get DATABASE_URL)"
REDIS_URL="$(heroku config:get REDIS_URL)"
heroku config:set QUEUESADILLA_DEFAULT_URL="${DATABASE_URL}"
heroku config:set CACHE_DEFAULT_URL="${REDIS_URL}?prefix=${APP_NAME}_"
heroku config:set CACHE_CAKECORE_URL="${REDIS_URL}?prefix=${APP_NAME}_cake_core_"
heroku config:set CACHE_CAKEMODEL_URL="${REDIS_URL}?prefix=${APP_NAME}_cake_model_"
```

One thing that needs to be done is we need to ensure we build assets in heroku, or our admin won't be able to render assets. I ran the following command locally:

```shell
mkdir webroot/cache_css webroot/cache_js
```

Then I added those directories to my `.gitignore`:

```shell
/webroot/cache_css
/webroot/cache_js
```

And finally, I added the following to the application's `composer.json` in `scripts.compile`:

```json
"mkdir webroot/cache_css webroot/cache_js",
"bin/cake asset_compress build"
```

And I'll commit these changes:

```shell
git add .gitignore composer.json
git commit -m "Build assets on deploy"
```

Finally, we'll need to square away our logging setup.

```shell
heroku config:set LOG_DEBUG_URL="syslog://logs?levels[]=notice&levels[]=info&levels[]=debug&file=debug"
heroku config:set LOG_ERROR_URL="syslog://logs?levels[]=warning&levels[]=error&levels[]=critical&levels[]=alert&levels[]=emergency&file=error"
```

Now push your code:

```shell
git push heroku master
```

You'll see a lot of build output, but once it is done, you can type `heroku open` to open your site in the browser.

## Background workers

You can add background queue workers by adding the following to your `Procfile` if it does not already exist:

```yaml
worker: bin/cake queuesadilla
```

Then commit and push the change:

```shell
git add Procfile
git commit -m "Allow running a background worker"
git push heroku master
```

To start a worker, you'll need to scale it up:

```shell
heroku ps:scale worker=1
```

## Logging in

You'll need to create a user to login as. To do so, you can start a new heroku dyno:

```php
heroku run bash
```

And then run our helper `UserShell` to create the first user:

```shell
bin/cake user --username-field email
```

## Homework Time: Uploading images

This will require a bit of reworking. Firstly, data is not persisted, so we need to store it on an external filesystem. I prefer [AWS S3](http://flysystem.thephpleague.com/adapter/aws-s3-v3/) for storing static files. Fortunately, flysystem supports quite adapters for different storage engines, so you can use whatever you'd like.

There are two places in the codebase you'll need to edit:

- `UsersTable`: The `Josegonzalez/Upload` behavior can be configured to use any adapter. Documentation [here](https://cakephp-upload.readthedocs.io/en/latest/configuration.html) on that.
- `PhotoPostType`: The adapter configured for upload is the `Local` adapter. Use whichever one you feel most comfortable.

I won't be making these changes in my version, but in a future release of my client's CMS, these two should be configurable :)

---

> For those that may just want to ensure their codebase matches what has been done so far, the codebase is available on GitHub and tagged as [0.0.24](https://github.com/josegonzalez/cakeadvent-2016/tree/0.0.24).

And that's a rap! We've created a fully-functioning CMS with:

- Image uploading
- Custom theme support
- CrudView-generated admin dashboard
- User authentication
- Password reset flows
- Email sending and previews
- Background queues
- Simple ecommerce functionality

Lots of stuff here for really not much code, and it was all thanks to the power of CakePHP.

Be sure to follow along via twitter on [@savant](https://twitter.com/savant). If you'd like to subscribe to this blog, you may follow the [rss feed here](/atom.xml). Also, all posts in the series will be conveniently linked on the sidebar of every post in the 2016 CakeAdvent Calendar.

Hope you all had as much fun as I did with this year's CakeAdvent Calendar. Until next post, take care and happy holidays!
