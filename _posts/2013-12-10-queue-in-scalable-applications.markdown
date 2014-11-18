---
  title:       "Queue in scalable applications"
  date:        2013-12-10 02:37
  description: "Don't make your users wait on the server. Instead, move long-running computations to the background and keep your conversions high"
  category:    CakePHP
  tags:
    - background-jobs
    - CakeAdvent-2014
    - cakephp
    - queuing
  comments:    true
  sharing:     true
  published:   true
  layout:      post
  series:      CakeAdvent
---

> This tutorial assumes you are using the FriendsOfCake/app-template project with Composer. Please see [this post for more information](http://josediazgonzalez.com/2013/12/08/composing-your-applications-from-plugins/).

One of the things I find developers doing - CakePHP and otherwise - is performing longer tasks when the user clicks a button. For example, in the application I work on, our main source of income depends upon inserting a record into a database table that is rapidly growing larger and slower. Boo. Our application could otherwise run off of a readonly database, and if we have to migrate our primary database, we are SOL.

A better way would be to use a queuing system. Instead of inserting into this table, we would chuck a job into our queuing system. This would both allow us to run in a readonly state as well as ensure that database issues don't affect our ability to make money.

Many CakePHP developers do something similar: creating image thumbnails at image upload time. That is one of the worst things you can do, as it can fail in many ways. Instead, lets use a queuing system.

## Choosing a queue

### Datastores

One of the toughest parts of choosing a background job system is what the datastore will be. There are many datastores which a job system can be built upon:

- Redis
- SQL (MySQL, Postgres, etc.)
- RabbitMQ
- Riak
- Starling
- SQS
- Unix Pipes!

Choosing the one that will best serve you has to do with any and all of the following:

- Your companies ability to run a new datastore
- Your familiarity with maintaining the system
- The ability of the system to perform to your specifications
- Acceptible failure modes
- Patterns you'd like to implement in your system (1 payload => Multiple jobs etc.)

The easiest choice is using SQL, as you likely have a database available and it's trivial to implement job-locking semantics in code. In fact, I wrote a wrapper called [CakeDjjob](https://github.com/josegonzalez/cakephp-cake-djjob) for such a system.

Generally speaking, always choose the easiest system to install, maintain, and develop against. If that happens to be MySQL, worse things have happened. You'll live.

I advocate for a system similar to RabbitMQ if at all possible, and it is what I use in production.

### Background Job Systems

Do you want a job system, or a message queue? That is the main question when choosing a setup. For example, you might implement a job system *on top of* a messaging queue, so you can think of a message queue as a super-set of a job system.

RabbitMQ - and other 0MQ systems - all implement message queues (MQ stands for message queue). You send a message into the system, and that message is shipped through multiple exchanges, finally landing on workers. This gives a single message the ability to spawn multiple jobs related to that message, depending upon the routing key and exchange the job is published on. For example, updating a database record would kick of a `database_update` on the `db` exchange, which makes it through to the `update_api` and `regenerate_image` queues. This is very powerful, in that new job workers can be created without needing to publish any additional queues.

Redis/MySQL/MongoDB based job systems typically implement a single message payload => single job run. It's much easier to understand this as it's more typical of job systems people have used. For example, DJJob implements this in MySQL:

- Insert a job into the `jobs` table under the `database_update` queue
- Have a worker read the latest record in the `database_update` queue.
- Worker acquires a lock on the job
- Worker queues up an `update_api` and a `regenerate_image` job to their respective queues.
- Worker deletes the job when done, and starts reading for a new job

This system would obviously perform more work, but is simpler for a developer to understand. Resque - a job system originating in Rubyland that has since been re-implemented in PHP and CakePHP - implements a similar pattern.

Personally, I'd choose RabbitMQ and implement my own system on top of it, then Resque or Djjob if I didn't want to setup/maintain RabbitMQ.

## Queuing in CakePHP

### The setup

Given the above, lets play with a simple example. We'll use [php-queuesadilla](https://github.com/josegonzalez/php-queuesadilla), a project that is under development and is intended to showcase how Queues might work in CakePHP. Install it in your `composer.json`:

```php
"josegonzalez/queuesadilla": "dev-master"
```

And run `composer update`. Because it is framework-agnostic, it will serve our purposes well. We're going to utilize MySQL as the backing store for this project, so you'll want to run the following create table statement:

```sql
CREATE TABLE IF NOT EXISTS `jobs` (
    `id` mediumint(20) NOT NULL AUTO_INCREMENT,
    `queue` char(32) NULL DEFAULT 'default',
    `data` mediumtext NULL DEFAULT '',
    `locked` tinyint(1) NULL DEFAULT 0,
    PRIMARY KEY (`id`),
    KEY `queue` (`queue`, `locked`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 AUTO_INCREMENT=1 ;
```

> The library actually supports Mysql, in-memory and Redis as backing queues, in case you wanted to follow along with a different backend.

### Wrapping the Library

Assuming you have composer autoloading available in CakePHP, the only thing left is to setup some simple CakePHP integration. We'll create a `CakeQueuesadilla` class:

```php
<?php
class CakeQueuesadilla {
  public $settings = null;

  protected $_baseConfig = array(
    'backend' => 'josegonzalez\\Queuesadilla\\Backend\\MemoryBackend',
    'queue' => 'default'
  );

  protected $_backend = null;

  protected $_queue = null;

  public function __construct() {
    $this->settings = array_merge(
      $this->_baseConfig,
      Configure::read('Queuesadilla.backend')
    );
  }

  public function backend() {
    if (!$this->_backend) {
      $backendClass = $this->settings['backend'];
      $this->_backend = new $backendClass($this->settings);
    }
    return $this->_backend;
  }

  public function queue() {
    if (!$this->_queue) {
      $this->_queue = new josegonzalez\Queuesadilla\Queue($this->backend());
    }

    return $this->_queue;
  }

  public function push($callable, $data, $queue = null) {
    return $this->queue()->push($callable, $data, $queue);
  }
}
?>
```

The above class is a wrapper around the Queuesadilla library to make it easier to consume. We'll configure it in our `bootstrap.php` as follows:

```php
<?php
Configure::write('Queuesadilla.backend', array(
  'backend' => 'josegonzalez\\Queuesadilla\\Backend\\MysqlBackend',
  'persistent' => true,
  'host' => 'localhost',
  'login' => 'root',
  'password' => 'password',
  'database' => 'queuesadilla',
  'port' => '3306',
  'table' => 'jobs',
  'queue' => 'default'
));
?>
```

### Queuing a Job

Now we will want to create a job! Lets send an email as a job:

```php
<?php
// app/Lib/Job/EmailJob.php
App::uses('CakeEmail', 'Network/Email');

class EmailJob {
  public static function run($job) {
    $Email = new CakeEmail();
    $Email->from(array('me@example.com' => 'My Site'));
    $Email->to($job->data('to'));
    $Email->subject($job->data('subject'));
    if ($Email->send($job->data('message'))) {
      print("Email Sent!");
    }
  }
}
?>
```

And to send the email in controller code, we would do the following:

```php
<?php
App::uses('CakeQueuesadilla', 'Lib');
App::uses('AppController', 'Controller');
class UsersController extends AppController {

  public function signup() {
    // signup logic
    $queuesadilla = new CakeQueuesadilla;
    $queuesadilla->push('EmailJob::run', array(
      'to' => 'user@example.com',
      'subject' => 'Example subject',
      'message' => 'Example message'
    ));
  }

}
?>
```

Hitting `http://example.com/users/signup` would queue up an email job like so:

```text
mysql> select * from jobs;
+----+---------+--------------------------------------------------------------------------------------------------------------------+--------+
| id | queue   | data                                                                                                               | locked |
+----+---------+--------------------------------------------------------------------------------------------------------------------+--------+
|  1 | default | {"class":"EmailJob::run","vars":{"to":"user@example.com","subject":"Example subject","message":"Example message"}} |      0 |
+----+---------+--------------------------------------------------------------------------------------------------------------------+--------+
```

### Running Jobs

Now that we've queued up the jobs, we'll want to run them. If we use the built-in runner, we'll have `Class Not Found` errors, so we should take care of that.

Any wrapper we create for the job system should be aware of our jobs. In PHP, you can specify multiple autoloaders, and doing so is likely the best way to handle this. Add the following to your bootstrap:

```php
<?php
spl_autoload_register(function($class) {
  // Check for anything that ends in `Job`
  if (strstr($class, 'Job') !== false) {
    // Requires the job class
    require APP . 'Lib/Job' . DS . $class . '.php';
  }
});
?>
```

We now need to add a way to run a worker. We'll place the following worker-generation code in our `CakeQueuesadilla` class:

```php
<?php
// ...

  public function worker($options = array()) {
    $options = array_merge(array(
      'max_iterations' => 5
    ), $options);

    $worker = new josegonzalez\Queuesadilla\Worker($this->backend(), $options);
    return $worker;
  }

?>
```

Next, we'll need a simple wrapper. We'll place this in `app/Console/queuesadilla`:

```php
#!/usr/bin/php -q
<?php
$ds = DIRECTORY_SEPARATOR;
$dispatcher = 'Cake' . $ds . 'Console' . $ds . 'ShellDispatcher.php';
if (function_exists('ini_set')) {
  $root = dirname(dirname(dirname(__FILE__))) . $ds . 'vendor' . $ds . 'cakephp' . $ds . 'cakephp';

  // the following line differs from its sibling
  // /lib/Cake/Console/Templates/skel/Console/cake.php
  ini_set('include_path', $root . $ds . 'lib' . PATH_SEPARATOR . ini_get('include_path'));
}

if (!include $dispatcher) {
  trigger_error('Could not locate CakePHP core files.', E_USER_ERROR);
}

// We must define these constants so class loading works properly with Composer
define('ROOT', dirname(dirname(dirname(__FILE__))));
define('APP', dirname(dirname(__FILE__)) . $ds);
define('APP_DIR', basename(dirname(dirname(__FILE__))));

unset($paths, $path, $dispatcher, $root, $ds);

class QueuesadillaDispatcher extends ShellDispatcher {
  public function __construct($args = array(), $bootstrap = true) {
    set_time_limit(0);
    $this->parseParams($args);

    if ($bootstrap) {
      $this->_initConstants();
      $this->_bootstrap();
    }
  }

  public static function run($argv) {
    $dispatcher = new QueuesadillaDispatcher($argv);
  }
}

QueuesadillaDispatcher::run($argv);

App::uses('CakeQueuesadilla', 'Lib');

$queuesadilla = new CakeQueuesadilla;
$worker = $queuesadilla->worker();
$worker->work();
?>
```

You'll recognize much of the above from the tutorial on using `Boris` as a CakePHP REPL. There are some minor changes for improved support with the `friendsofcake/app-template` project, but nothing too scary.

To start a worker, simply run `Console/queuesadilla`. It will run a worker on the default queue:

```bash
[Mysql Worker] Starting worker, max iterations 5
Email Sent!
[Mysql Worker] Success. Deleting job from queue.
[Mysql Worker] No job!
[Mysql Worker] No job!
[Mysql Worker] No job!
[Mysql Worker] No job!
[Mysql Worker] Max iterations reached, exiting
```

Great success!

### Why use jobs

You generally want to chuck long-running processes, or expensive calculations, into background jobs. They are useful for tasks that can be delayed or do not need an immediate response. Here are a few things I use them for in production at my day job:

- Delayed Email Sending
- FTP Upload Processing
- Push Notifications for iOS/Android
- Creating large files for partners
- Regenerating api entries

While `Queuesadilla` isn't quite ready for primetime, it does show how effective a queuing system can be when used properly. Using a Job system can help reduce the load on your web servers and increase the responsiveness of your web application. Hopefully this blog post helps push you towards more scalable applications :).

