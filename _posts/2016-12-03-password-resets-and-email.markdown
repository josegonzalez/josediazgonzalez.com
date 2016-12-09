---
  title:       "Password Resets and Email"
  date:        2016-12-03 1:40
  description: "Part 3 of a series of posts that will help you build out a personal CMS"
  category:    cakephp
  tags:
    - passwords
    - email
    - cakeadvent-2016
    - cakephp
  comments:    true
  sharing:     true
  published:   true
  layout:      post
  disable_advertisement: true
  series:      CakeAdvent-2016
  og_image:    /images/2016/12/03/reset-password-page.png
---

A friend of mine asked for a custom website, so here I am, writing a custom cms. I know, there are plenty of systems out there that would handle his needs, but it's also a good excuse to play around with CakePHP 3, so here we are.

> For the lazy, the codebase we'll be working on will be available on [GitHub](https://github.com/josegonzalez/cakeadvent-2016). I will be pushing each set of changes on the date when each blog post in this series is published. No cheating!

## Errata from last post

- I fixed a few typos in executing the `users` shell. Specifically, the `username-field` flag should have a value of `email`
- In CakePHP 3.x, you no longer specify `admin => true|false` when configuring the `AuthComponent`. It should be `prefix => false|PREFIX_NAME`.
- The preferred method of retrieving values from the request object is not `ArrayAccess`, but via a method. You should use `$this->request->param('field')` instead of the array-method.
- I've removed the type-hint on `AppController::isAuthorized()` and `UsersController::isAuthorized()`. The docblock states that they can also accept `ArrayAccess`, so `array` as a type-hint was inappropriate. In the recently released PHP 7.1, you can instead use `iterable` as a type-hint.
- The `config/bootstrap.php` file is missing the `Plugin::load('CrudUsers');` statement. You can add it manually or using the cli tool as follows:

  ```shell
  bin/cake plugin load CrudUsers
  ```

Thanks to those who've pointed out my derps. These fixes are available as the first commit in the current release.

## Updating Plugins

Before we continue, lets be sure we've updated all our plugins. I like to do this each day so that I can get any bugfixes that come out for libraries my application depends upon. In this case, there are a few bugfixes for some CakePHP plugins, so we'll grab those with the following `composer` command:

```php
composer update
```

Typically you would run tests at this stage, but since we have _yet_ to write any, that isn't necessary.

Let's commit any updates:

```shell
git add composer.lock
git commit -m "Update patch-level for all plugins"
```

> You should always verify your application still works after upgrading dependencies.

## Reset Password Flow

First, we need a reset password flow.

> This workflow is vulnerable to email enumeration. Keep this in mind when implementing this in your application. You might want to look into some sort of rate-limiting for the `/users/forgot-password` endpoint...

{% ditaa %}
/----------------------------+ send email /---------------------------------+
| GET /users/forgot-password |----------->| GET /users/reset-password/TOKEN |
+----------------------------+            +----------------+----------------+
                                                           |
                                                           v
/------------------------+  verify token  /----------------------------------+
|     password reset!    |<---------------| POST /users/reset-password/TOKEN |
+------------------------+ enter new pass +----------------------------------+
{% endditaa %}

Seems pretty reasonable. We will start be hooking up the appropriate crud actions for this.

## Enabling the Crud Actions

> Using Crud actions is going to become more or less second nature in this app. Get used to it?

Add the following three lines to your `UsersController::initialize()` method. This will map the `forgotPassword`, `resetPassword`, and `verify` actions, as well as allow anonymous access to each.

```php
$this->Crud->mapAction('forgotPassword', 'CrudUsers.ForgotPassword');
$this->Crud->mapAction('resetPassword', [
    'className' => 'CrudUsers.ResetPassword',
    'findMethod' => 'token',
]);
$this->Crud->mapAction('verify', [
    'className' => 'CrudUsers.Verify',
    'findMethod' => 'token',
]);
$this->Auth->allow(['forgotPassword', 'resetPassword', 'verify']);
```

These three actions require the following fields for usage:

- `token`: A string field storing a reset token.
- `verified`: A boolean database field.

### Adding the `verified` field

To get the verified field, we'll create a migration:

```shell
bin/cake bake migration add_verified_field_to_users verified:boolean
```

Once generated, you'll want to set the `verified` field default to either `true` or `false`. I set mine to `true`, because we'll only ever have a single verified user in this blog.

And now we can run it.

```shell
bin/cake migrations migrate
```

### Adding the `token` field

To add the token field, we _could_ generate a migration and run it, but then we'd have to worry about generating tokens themselves. The `CrudUsers.ForgotPassword` action class *does not generate tokens*. I'd rather not have to deal with that logic, so we'll lean on _yet another plugin_, the `Muffin/Tokenize` plugin.

> Doesn't it seem like I love plugins? In truth, I just am very lazy, so I lean on them heavily. Write once, use forever.

Lets install it first:

```shell
composer require muffin/tokenize
```

Next, we'll need to enable it and run it's migrations:

```shell
# enable the plugin (with routes and bootstrapping)
bin/cake plugin load Muffin/Tokenize --bootstrap --routes

# run migrations
bin/cake migrations migrate --plugin Muffin/Tokenize
```

The `Muffin/Tokenize` plugin doesn't actually store tokens in the `users` table. It creates a separate table and stores them there. For our next act, we'll be actually sending the email and properly verifying that the user exists. Let's save our progress for now.

```shell
git add composer.json composer.lock config/Migrations/* config/bootstrap.php src/Controller/UsersController.php
git commit -m "Initial setup for password reset flow"
```

## Event Listeners and Mailers

In order to actually trigger email sending, we're going to create a few classes and traits. Specifically, we need to:

- Be able to properly retrieve tokens from our related table
- Ensure we send emails
- Verify tokens correctly

### Finding muffin tokens

First things first, we'll need to be able to lookup a token. To do so, we'll need to add the `Muffin/Tokenize.Tokenize` behavior to our `UsersTable::initialize()` method, located in `src/Model/Table/UsersTable.php`:

```php
$this->addBehavior('Muffin/Tokenize.Tokenize');
```

Now that the behavior is loaded, we have setup a relation from the `UsersTable` to the `TokensTable` from the `Muffin/Tokenize` plugin. We'll also need a custom `find` method to bind that in.

> Find methods are functions that describe how to query a table for entities. You can chain multiple find methods together to create new, more powerful finds. The built-in finds are `all`, `list`, and `threaded`.

I personally like placing finds in traits, so that on the off-chance I need to use them elsewhere, I can. It also allows me to test the finds in isolation of any customizations performed in `Table` classes. The following should go in `src/Table/Traits/TokenFinderTrait.php`:

```php
<?php
namespace App\Model\Table\Traits;

trait TokenFinderTrait
{
    /**
     * Find user based on token
     *
     * @param \Cake\ORM\Query $query The query to find with
     * @param array $options The options to find with
     * @return \Cake\ORM\Query The query builder
     */
    public function findToken($query, $options)
    {
        return $this->find()->matching('Tokens', function ($q) use ($options) {
            return $q->where(['Tokens.token' => $options['token']]);
        });
    }
}
```

This will retrieve a user that is associated with a given token. In order to use this trait, you'll need to add the following *inside* the `UsersTable` class:

```php
use \App\Model\Table\Traits\TokenFinderTrait;
```

You can commit this small change now:

```shell
git add src/Model/Table/UsersTable.php src/Model/Table/Traits/TokenFinderTrait.php
git commit -m "Enable finding reset tokens"
```

### Event Listeners

Halfway there. The `CrudUsers.ForgotPassword` action class uses the `afterForgotPassword` event to do the heavy lifting of notifying users of a password reset. We'll need to handle it in our own event listener. You can do this via either a callable class - boo, hiss, hard to test - or via a nice Listener class. I'm going to do the latter, because it is cleaner. Add the following to `src/Listener/UsersListener.php`

```php
<?php
namespace App\Listener;

use Cake\Event\Event;
use Cake\Mailer\MailerAwareTrait;
use Cake\ORM\TableRegistry;
use Crud\Listener\BaseListener;

/**
 * Users Listener
 */
class UsersListener extends BaseListener
{
    use MailerAwareTrait;

    /**
     * Default config for this object.
     *
     * @var array
     */
    protected $_defaultConfig = [
        'mailer' => 'Users.User',
    ];

    /**
     * Callbacks definition
     *
     * @return array
     */
    public function implementedEvents()
    {
        return [
            'Crud.afterForgotPassword' => 'afterForgotPassword',
        ];
    }

    /**
     * After Forgot Password
     *
     * @param \Cake\Event\Event $event Event
     * @return void
     */
    public function afterForgotPassword(Event $event)
    {
        if (!$event->subject->success) {
            return;
        }

        $table = TableRegistry::get($this->_controller()->modelClass);
        $token = $table->tokenize($event->subject->entity->id);

        if ($this->config('mailer')) {
            $this->getMailer($this->config('mailer'))->send('forgotPassword', [
                $event->subject->entity->toArray(),
                $token,
            ]);
        }
    }
}
```

This is a basic [event listener](http://book.cakephp.org/3.0/en/core-libraries/events.html#registering-listeners). We define a list of `implementedEvents`, map them to functions, and have our event logic in those functions. In this case, we're using Crud internals to automatically get stuff like:

- The current controller's model
- Ensure we implement a listener in the form that Crud wants (which is merely a bit of sugar on top of a regular CakePHP event listener)
- Get and set custom configuration.

One thing you'll notice is that we've added the `MailerAwareTrait`. This trait is used to enable usage of CakePHP `Mailers`, which are classes that store reusable email configuration. They are new in CakePHP 3.1, and while it's certainly not how I used to write emails, I've come to appreciate them.

> It's classes and traits all the way down! How do I keep track of all of these things? It's mostly practice, as you can certainly do without most of this, but the separation allows us to cleanly refactor bits and pieces of code, as well as test individual pieces of logic.

In our listener, we've specified the `UserMailer`, which lives in `src/Mailer/UserMailer.php`. We are using `forgotPassword` method of that mailer to send our email. If you've ever sent an email in CakePHP, you'll be right at home. If not, it's a pretty easy read. Below is the contents of that class:

```php
<?php
namespace App\Mailer;

use Cake\Mailer\Mailer;

class UserMailer extends Mailer
{
    /**
     * Email sent on password recovery requests
     *
     * @param array $user User information, must includer email and username
     * @param string $token Token used for validation
     * @return \Cake\Mailer\Mailer
     */
    public function forgotPassword($user, $token)
    {
        return $this->to($user['email'])
            ->subject('Reset your password')
            ->template('forgot_password')
            ->layout(false)
            ->set([
                'token' => $token,
            ])
            ->emailFormat('html');
    }
}
```

We have our listener and mailer setup, so now all we have to do is attach it to Crud and test it out. To begin, add the following line to your `UsersController`:

```php
$this->Crud->addListener('Users', 'App\Listener\UsersListener');
```

Next, we'll need `html` and `text` templates for sending out these emails. The following are what I use in `src/Template/Email/html/forgot_password.ctp` and `src/Template/Email/text/forgot_password.ctp` (in that order):

```php
<?php
use Cake\Routing\Router;
$url = Router::url(
    [
        'controller' => 'users',
        'action' => 'verify',
        $token
    ],
    true
);
?>
<html>
<head>
    <title><?= $this->fetch('title') ?></title>
</head>
<body>
    <?= $this->fetch('content') ?>
    <h1>Set your password...</h1>
    <p>
        A password recovery link has been requested for your account. If you
        haven't requested this, please ignore this email.
    </p>
    <p>
        <?= $this->Html->link('Click here to reset your password', $url) ?>
    </p>
</body>
</html>
```

```php
<?php
use Cake\Routing\Router;
$url = Router::url(
    [
        'controller' => 'users',
        'action' => 'verify',
        $token
    ],
    true
);
?>

A password recovery link has been requested for your account. If you haven't requested this, please ignore this email.

Click here to reset your password: <?= $url ?>
```

Finally, we'll need a `forgotPassword` template, which should go in `src/Template/Users/forgot_password.ctp`. This will be used to present the forgot password form to our users.

```php
<div class="users form">
<?= $this->Flash->render('auth') ?>
    <?= $this->Form->create() ?>
    <fieldset>
        <legend><?= __('Please enter your email to send a reset email') ?></legend>
        <?= $this->Form->input('email') ?>
    </fieldset>
    <?= $this->Form->button(__('Reset password')); ?>
    <?= $this->Form->end() ?>
</div>
```

Since we're in a good place regarding the "forgot password" step, lets save our progress.

```shell
git add src/Controller/UsersController.php src/Listener/UsersListener.php src/Mailer/UserMailer.php src/Template/Email/html/forgot_password.ctp src/Template/Email/text/forgot_password.ctp src/Template/Users/forgot_password.ctp
git commit -m "Implement forgot-password phase"
```

### Verifying Tokens

Once we are capable of sending emails, we'll want to verify that the token being sent in the email is both a token we know about and is valid. The `ResetPassword` action class does this by emitting a `verifyToken` event, which we can listen to in our `UsersListener`.

> Tokens are a one-time use deal, and the `Muffin/Tokenize` plugin expires them in three days (configurable!).

 We'll need to first tell the listener that we have an implementation of the event handler by adding the following entry to the array our `UsersListener::implementedEvents()` returns:

```php
'Crud.verifyToken' => 'verifyToken',
```

And now for the implementation, we'll want to call into the `Muffin/Tokenize` plugin and just call `verify()` on the token like so:

```php
    /**
     * Before Verify
     *
     * @param \Cake\Event\Event $event Event
     * @return void
     */
    public function verifyToken(Event $event)
    {
        $event->subject->verified = TableRegistry::get('Muffin/Tokenize.Tokens')
            ->verify($event->subject->token);
    }
```

We also need the `reset_password` template. Place the following in `src/Template/Users/reset_password.ctp`:

```php
<div class="users form">
<?= $this->Flash->render('auth') ?>
    <?= $this->Form->create() ?>
    <fieldset>
        <legend><?= __('Enter a new password to reset your account') ?></legend>
        <?= $this->Form->input('password') ?>
    </fieldset>
    <?= $this->Form->button(__('Signin')) ?>
    <?= $this->Form->end() ?>
</div>
```

That's it, that's all! Lets commit it!

```shell
git add src/Listener/UsersListener.php src/Template/Users/reset_password.ctp
git commit -m "Verify user tokens"
```

### Testing the Whole Flow

In order to send email, we'll need to configure a transport properly. You can do this in your `config/.env` file, by changing the `EMAIL_TRANSPORT_DEFAULT_URL` value to the desired configuration. I personally set mine to match my gmail credentials for now, though you'll likely want to use something a bit more bulletproof. I'm not sure yet what we'll use once we get to deploying this, but we'll cross that bridge when we need to. Here is what I set mine to (minus a valid `username:password` combination):

```shell
export EMAIL_TRANSPORT_DEFAULT_URL="smtp://username:password@smtp.gmail.com:587/?client=null&timeout=30&tls=true"
```

Finally, lets test sending this email. Browse to `/users/forgot-password`, enter in the email address you set for your user earlier, submit the form, and check your email. If everything was configured properly - it was for me! - you'll see an email like the following in your inbox:

![reset password email](/images/2016/12/03/reset-password-email.png)

> Yes, my email avatar is a cat with a kermit hat. Deal with it.

This seems good so far. Click on the link to be taken to the following page:

![reset password page](/images/2016/12/03/reset-password-page.png)

And fill in your new password to reset your account.

Seems legit!

## Default landing page

You'll notice that once you reset your password, you were redirected to the login page. If you try and login, you'll land right back on the login page with two messages, one saying you are logged in, and one saying you do not have access. This is because we have made the app such that all controller/action pairs *must* be individually allowed. Lets fix that and at least allow a landing page.

For now, our landing page will be the list of blog posts. We'll need to first ensure that `/` points at `PostsController::index()`. This is done by editing our application's routes in `config/routes.php`.

> Routes are how CakePHP knows what an incoming url points to in the application. A common use for changing routing is to add vanity urls. You can do all sorts of funny stuff with routes, as well see in later posts. CakePHP has some sane defaults that make it easy for developers to get started, which is why our `/users/login`, `/users/forgot-password`, etc. urls all worked out of the box.

The default route should currently be as follows:

```php
$routes->connect('/', ['controller' => 'Pages', 'action' => 'display', 'home']);
```

We're going to update it to the following:

```php
$routes->connect('/', ['controller' => 'Posts', 'action' => 'index']);
```

Next, lets allow access to this action in our `PostsController`. We'll need a custom `PostsController::initialize()`. Here is what you should add to the `PostsController`.

```php
    /**
     * Initialization hook method.
     *
     * Use this method to add common initialization code like loading components.
     *
     * e.g. `$this->loadComponent('Security');`
     *
     * @return void
     */
    public function initialize()
    {
        parent::initialize();
        $this->Auth->allow(['index']);
    }
```

Why wouldn't we have an `PostsController::isAuthorized()`? That method applies only to already logged in users. Anonymous users would never be able to access the page, regardless of what you return from `isAuthorized()`.

You should now be able to access `/`, both before and after logging in. Let's commit what we have and end for today.

```shell
git add config/routes.php src/Controller/PostsController.php
git commit -m "Allow logged in and anonymous access to an initial / route"
```

---

> For those that may just want to ensure their codebase matches what has been done so far, the codebase is available on GitHub and tagged as [0.0.3](https://github.com/josegonzalez/cakeadvent-2016/tree/0.0.3).

Hurray, we have some authentication configured for our application, are sending emails, have figured out how to customize Crud for our usage, and even have a landing page. Tomorrow we'll work on allowing the blog user to edit their account, and potentially even get to image uploading.

Be sure to follow along via twitter on [@savant](https://twitter.com/savant). If you'd like to subscribe to this blog, you may follow the [rss feed here](/atom.xml). Also, all posts in the series will be conveniently linked on the sidebar of every post in the 2016 CakeAdvent Calendar. Come back tomorrow for more delicious content.
