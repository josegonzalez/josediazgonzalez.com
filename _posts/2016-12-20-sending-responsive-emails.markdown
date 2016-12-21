---
  title:       "Sending Responsive Emails"
  date:        2016-12-20 07:02
  description: "Part 20 of a series of posts that will help you build out a personal CMS"
  category:    cakephp
  tags:
    - emails
    - email-preview
    - cakeadvent-2016
    - cakephp
  comments:    true
  sharing:     true
  published:   true
  layout:      post
  disable_advertisement: true
  series:      CakeAdvent-2016
  og_image:    /images/2016/12/20/better-email-preview.png
---

A friend of mine asked for a custom website, so here I am, writing a custom cms. I know, there are plenty of systems out there that would handle his needs, but it's also a good excuse to play around with CakePHP 3, so here we are.

> For the lazy, the codebase we'll be working on will be available on [GitHub](https://github.com/josegonzalez/cakeadvent-2016). I will be pushing each set of changes on the date when each blog post in this series is published. No cheating!

## Email Previewing

One thing that has always annoyed me about developing emails within an application is that the preview step is pretty manual. I do agree that all emails should be seen in the actual email clients - all clients render at least slightly differently - but I personally hate the following workflow:

- Update email
- Send test email to client
- Wait until client has received the email
- Check email
- Repeat until done

It's sort of annoying to go through, and not very nice for rapid application development. Fortunately, there is a solution! We'll use my [MailPreview](https://github.com/josegonzalez/cakephp-mail-preview) plugin to shorten the development cycle significantly. Start off my installing it:

```shell
composer require josegonzalez/cakephp-mail-preview
```

Next, we'll want to load the plugin (and it's routes):

```shell
bin/cake plugin load Josegonzalez/MailPreview --routes
```

The `MailPreview` plugin integrates with the CakePHP `Mailer` class, but currently requires a single addition to get previews going. We'll need to add the following `use` statement to `UserMailer` class declaration:

```php
use Josegonzalez\MailPreview\Mailer\PreviewTrait;
```

And we'll need to add the trait usage *inside* of the class:

```php
use PreviewTrait;
```

Now we can create a `MailPreview` class for our `UserMailer`. Think of the `MailPreview` class as a type of fixture, except it provides testing data for emails instead of databases. I'll create a `UserMailPreview` in `src/Mailer/Preview/UserMailPreview.php` with the following contents:

```php
<?php
namespace App\Mailer\Preview;

use Josegonzalez\MailPreview\Mailer\Preview\MailPreview;

class UserMailPreview extends MailPreview
{
    public function forgotPassword()
    {
        return $this->getMailer('User')
                    ->preview('forgotPassword', [
                        'example@example.com',
                        'some-test-token'
                    ]);
    }
}
```

The usage is pretty straightforward. The `PreviewTrait` adds a `preview()` method to the Mailer, which takes in the name of the email and the arguments to send that email. The return is then used to show what the email looks like on screen.

In order to display the previews, we'll need to allow the actions if the controller is the `MailPreviewController`. I added the following to my `AppController::initialize()` method:

```php
if ($this->request->params['controller'] == 'MailPreview') {
    $this->Auth->allow();
}
```

If you browse to `/mail-preview`, you will see a list of your mailers and the emails they contain. If you click on one, you'll get a weird routing error. Why? Because we are in a plugin, all urls are scoped to this plugin, and since the urls in question are not mapped, boom goes the email. Fix that by adding `'plugin' => null` to the urls in your `forgot_password.ctp` templates, and you should see the following in your browser:

![email preview](/images/2016/12/20/email-preview.png)

> Always be explicit about your urls!

Pretty good, right? Now we can work on our email to our hearts content! We'll save our progress here.

```shell
git add composer.json composer.lock config/bootstrap.php src/Controller/AppController.php src/Mailer/UserMailer.php src/Template/Email/html/forgot_password.ctp src/Template/Email/text/forgot_password.ctp src/Mailer/Preview/
git commit -m "Setup email previews"
```

## Displaying a Responsive Email

I more or less am going to grab the layout template from [leemunroe/responsive-html-email-template](https://github.com/leemunroe/responsive-html-email-template) with a few minor tweaks:

- Replaced the `<title>` element contents with `<?= $this->fetch('title') ?>`
- Replaced the body with `<?= $this->fetch('content') ?>`

You can modify the email otherwise however you see fit. I placed mine in `src/Template/Layout/Email/html/default.ctp`. In order to load this layout, I removed `->layout(false)` from my `UserMailer::forgotPassword()` method.

With a few minor changes, my email now looks like this:

![better email preview](/images/2016/12/20/better-email-preview.png)

I'll save my work for now, but here are a few ideas to try:

- Setup some sort of email unsubscribe flow.
- Add images or backgrounds to your emails.
- Create an `EmailHelper` to make adding buttons etc. easier.

```shell
git add src/Mailer/UserMailer.php src/Template/Email/html/forgot_password.ctp src/Template/Layout/Email/html/default.ctp
git commit -m "Nicer html email layout"
```

---

> For those that may just want to ensure their codebase matches what has been done so far, the codebase is available on GitHub and tagged as [0.0.20](https://github.com/josegonzalez/cakeadvent-2016/tree/0.0.20).

Looks like I lied about what we were going to work on today, but I wanted to go back and show off a neat development feature I'd been working on. I think the results speak for themselves, and hope it was a worthwhile trip. Tomorrow we'll *actually* work on selling photos.

Be sure to follow along via twitter on [@savant](https://twitter.com/savant). If you'd like to subscribe to this blog, you may follow the [rss feed here](/atom.xml). Also, all posts in the series will be conveniently linked on the sidebar of every post in the 2016 CakeAdvent Calendar. Come back tomorrow for more delicious content.
