---
  title:       "Queuing up emails"
  date:        2016-12-18 06:26
  description: "Part 18 of a series of posts that will help you build out a personal CMS"
  category:    cakephp
  tags:
    - queuing
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

## Emailing in the Background

One thing you may notice is that sending the "forgot password" email causes the site to slow down. There are a few things to think about here:

- Users will get upset if their requests don't complete "instantly".
- Google will actually penalize slower sites in their rankings
- If you perform more work in a web request, those requests can build up, potentially allowing users to DDoS you.


Overall, it's pretty jank to send emails in the foreground. We'll instead queue the messages to be sent in the background using the [`josegonzalez/cakephp-queuesadilla`](https://github.com/josegonzalez/cakephp-queuesadilla) plugin which is included with the `josegonzalez/app` skeleton we are using.

> CakePHP does not yet have an official queueing library, though we hope to have one soon. My hope is that it will be a slightly repackaged Queuesadilla.

### Creating a Job class

We'll start by creating a generic `MailerJob` class in `src/Job/MailerJob.php`. Here is the contents of that file:

```php
<?php
namespace App\Job;

use Cake\Log\LogTrait;
use Cake\Mailer\MailerAwareTrait;
use josegonzalez\Queuesadilla\Job\Base as JobContainer;

class MailerJob
{
    use LogTrait;
    use MailerAwareTrait;

    public function execute(JobContainer $job)
    {
        $mailer = $job->data('mailer');
        $action = $job->data('action');
        $data = $job->data('data', []);

        if (empty($mailer)) {
            $this->log('Missing mailer in job config');
            return;
        }

        if (empty($action)) {
            $this->log('Missing action in job config');
            return;
        }

        $this->getMailer($mailer)->send($action, $data);
    }
}

```

Briefly, we'll go over this:

- Jobs can be either functions, static methods in classes, or instances with a method that we execute. We are going for the instance methodology.
- When a job method is executed, we pass in a `JobContainer` which has access to the relevant job data.
- We still use the `MailerAwareTrait` so that we can reuse our `Mailer` classes.
- The `MailerJob::execute()` method has been made generic so that we might be able to reuse this job for other cases where we'll send email.

### Queuing the `MailerJob`

This is relatively simple. We'll start by removing all `MailerAwareTrait` code from our `UsersListener`. In particular, remove the following `use` statement:

```php
use Cake\Mailer\MailerAwareTrait;
```

As well as the following from within the class:

```php
use MailerAwareTrait;

/**
 * Default config for this object.
 *
 * @var array
 */
protected $_defaultConfig = [
    'mailer' => 'User',
];
```

At this point, you should add the following `use` statement to the top of the class:

```php
use Josegonzalez\CakeQueuesadilla\Queue\Queue;
```

Finally, we'll update `UsersListener::afterForgotPassword()` to actually enqueue the job:

```php
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

    Queue::push(['\App\Job\MailerJob', 'execute'], [
        'action' => 'forgotPassword',
        'mailer' => 'User',
        'data' => [
            'email' => $event->subject->entity->email,
            'token' => $token,
        ]
    ]);
}
```

A few things:

- `Queue::push()` takes two arguments, a callable and data for the job.
- Our callable should include the fully-namespaced class name and the function being invoked, so `['\App\Job\MailerJob', 'execute']`.
- Our `MailerJob` requires an `action` and a `mailer` to be specified, so we pass those in as data, and also send in the user's email

Finally, we need to update our `UserMailer::forgotPassword()` signature so that we only need the `email` and not an entire `user` object.

```php
/**
 * Email sent on password recovery requests
 *
 * @param array $email User email
 * @param string $token Token used for validation
 * @return \Cake\Mailer\Mailer
 */
public function forgotPassword($email, $token)
{
    return $this->to($email)
        ->subject('Reset your password')
        ->template('forgot_password')
        ->layout(false)
        ->set([
            'token' => $token,
        ])
        ->emailFormat('html');
}
```

Before testing this, one thing that we'll need to do is make sure that we have specified a full base url for all environments. CakePHP will normally retrieve this from the current request, but cannot do so in a CLI environment. As such, we'll need to add the following to `line 17` of our `config/env.php`:

```php
'App.fullbaseurl' => 'App.fullBaseUrl',
```

Now we can set the `APP_FULLBASEURL` environment variable and have it properly scope all of our urls.

> Newer installs of the `josegonzalez/app` skeleton will not need the above change to your `config/env.php` file.

Lets save our changes:

```shell
git add config/env.php src/Job/MailerJob.php src/Listener/UsersListener.php src/Mailer/UserMailer.php
git commit -m "Send emails via a background job"
```

### Running Jobs

To run a job, we'll need to first create the requisite tables. Queusadilla can use a variety of backends, though we are defaulting to the PDO backend for ease of use. Let's run the migration for that:

```shell
bin/cake migrations migrate --plugin Josegonzalez/CakeQueuesadilla
```

Now we can just run the default queue:

```shell
bin/cake queuesadilla
```

And we're done!

---

> For those that may just want to ensure their codebase matches what has been done so far, the codebase is available on GitHub and tagged as [0.0.18](https://github.com/josegonzalez/cakeadvent-2016/tree/0.0.18).

We have no sped up our slowest endpoint by over 9000, which is great because I'm pretty sure the scouter is broken. For our next post, we'll do a bit more minor cleanup of our admin panels.

Be sure to follow along via twitter on [@savant](https://twitter.com/savant). If you'd like to subscribe to this blog, you may follow the [rss feed here](/atom.xml). Also, all posts in the series will be conveniently linked on the sidebar of every post in the 2016 CakeAdvent Calendar. Come back tomorrow for more delicious content.
