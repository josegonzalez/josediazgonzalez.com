---
  title:       "Creating Custom Background Shells"
  date:        2015-12-20 12:00
  description: "Silly hacks you can use in your cakephp applications"
  category:    cakephp
  tags:
    - cakeadvent-2015
    - cakephp
    - shells
    - queueing
  comments:    true
  sharing:     true
  published:   true
  layout:      post
  series:      CakeAdvent-2015
---

In a previous post, I mentioned how awesome it would be to have a background queueing system to perform long-running tasks. While there are many queueing systems, today I will re-introduce Queuesadilla, with an aim to explain how CakePHP shells work.

## Shell Skeleton

Before we being, lets start with understanding what we need:

- Queuesadilla is a long-running task. It handles it's own state, so if it crashes, all we really care about is ensuring whatever process manager we are using will restart it. Given that, we don't need much error handling.
- We should be able to configure most of the options in Queuesadilla. We might not use them today, but they will come in handy later.
- Logging should be done using the CakePHP logger.
- Default configuration should come from the `Configure` class, same as everything else.

Now that we know what we are building, let's bake the shell:

```shell
# install Queuesadilla
composer require josegonzalez/queuesadilla:dev-master

# bake the shell
bin/cake bake shell Queuesadilla
```

You should now have a `src/Shell/QueueShell.php` with contents similar to the following:

```php
<?php
namespace App\Shell;

use Cake\Console\Shell;

class QueueShell extends Shell
{
    public function main()
    {
    }
}
?>
```

You can invoke the shell with `bin/cake queue`, and you will see the following output:

```shell
$ bin/cake queue

Welcome to CakePHP v5.0.1 Console
---------------------------------------------------------------
App : src
Path: /Users/jose/src/playground/src/
PHP : 7.0.1
---------------------------------------------------------------
```

> Yes, that's CakePHP 5, and yes, it supports MRD (Mind Reading Development)

## Adding a layer

This isn't very helpful. Lets fill in that `main()` method with some logic:

```php
public function main()
{
    $EngineClass = "josegonzalez\\Queuesadilla\\Engine\\MysqlEngine';
    $WorkerClass = "josegonzalez\\Queuesadilla\\Worker\\SequentialWorker";

    $logger = \Cake\Log\Log::engine('default');
    $engine = new $EngineClass($logger, [
      'url' => 'mysql://user:password@localhost:3306/database_name'
    ]);

    $worker = new $WorkerClass($engine, $logger);
    $worker->work();
}
```

Assuming you have that database configured, this will work and output something similar to the following:

```
2015-12-22 00:54:39 Info: Starting worker
2015-12-22 00:54:39 Debug: No job!
2015-12-22 00:54:40 Debug: No job!
```

If we queued a job, you could see the job output as well. We don't care too much about that now, as we still need to ensure this thing can be configured for more than just our test app.

## Option Parsing

Every cakephp shell has a method called `getOptionParser()`. This returns an `ArgumentParser`.

---

Just kidding, it returns an `OptionParser`. You can add as many options as you'd like to this, and these options can later be accessed within your shell by using the `$this->params` array attribute. The following is what ours will look like:

```php
public function getOptionParser()
{
    $parser = parent::getOptionParser();
    $parser->addOption('engine', [
        'choices' => [
            'Beanstalk',
            'Iron',
            'Memory',
            'Mysql',
            'Null',
            'Redis',
            'Synchronous',
        ],
        'default' => 'Mysql',
        'help' => 'Name of engine',
        'short' => 'e',
    ]);
    $parser->addOption('queue', [
        'help' => 'Name of a queue',
        'short' => 'q',
    ]);
    $parser->addOption('logger', [
        'help' => 'Name of a configured logger',
        'default' => 'stdout',
        'short' => 'l',
    ]);
    $parser->addOption('worker', [
        'choices' => [
            'Sequential',
            'Test',
        ],
        'default' => 'Sequential',
        'help' => 'Name of worker class',
        'short' => 'w',
    ]);
    $parser->description(__('Runs a Queuesadilla worker'));
    return $parser;
}
```

The [online docs](http://book.cakephp.org/3.0/en/console-and-shells.html#configuring-options-and-generating-help) do a good job of explaining these and other ways of manipulating an `OptionParser`, but the above code should be pretty self-explanatory. With the above code, we'll have the following output for `bin/cake queue -h`:

```shell
$ bin/cake queue -h

Welcome to CakePHP v5.0.1 Console
---------------------------------------------------------------
App : src
Path: /Users/jose/src/playground/src/
PHP : 7.0.1
---------------------------------------------------------------
Runs a Queuesadilla worker.

Usage:
cake queuesadilla [options]

Options:

--help, -h     Display this help.
--verbose, -v  Enable verbose output.
--quiet, -q    Enable quiet output.
--engine, -e   Name of engine (default: Mysql)
               (choices:
               Beanstalk|Iron|Memory|Mysql|Null|Redis|Synchronous)
--queue, -q    Name of a queue
--logger, -l   Name of a configured logger (default:
               stdout)
--worker, -w   Name of worker class (default:
               Sequential) (choices:
               Sequential|Test)
```

Pretty chawesome. Let's modify our code to use this:

```php
public function main()
{
    $engine = $this->params['engine'];
    $worker = $this->params['worker'];
    $EngineClass = "josegonzalez\\Queuesadilla\\Engine\\" . $engine . 'Engine';
    $WorkerClass = "josegonzalez\\Queuesadilla\\Worker\\" . $worker . "Worker";

    $config = $this->getEngineConfig();
    $loggerName = $this->getLoggerName();

    $logger = \Cake\Log\Log::engine($loggerName);
    $engine = new $EngineClass($logger, $config);

    $worker = new $WorkerClass($engine, $logger);
    $worker->work();
}

protected function getEngineConfig()
{
    $config = \Cake\Core\Configure::read('Queuesadilla.engine');
    if (empty($config)) {
        throw new Exception('Invalid Queuesadilla.engine config');
    }

    if (!empty($this->params['queue'])) {
        $config['queue'] = $this->params['queue'];
    }
    return $config;
}

protected function getLoggerName()
{
    $loggerName = \Cake\Core\Configure::read('Queuesadilla.logger');
    if (empty($loggerName)) {
        $loggerName = $this->params['logger'];
    }
    return $loggerName;
}
```

The only thing left to do is add the appropriate config to our `config/app.php`:

```php
'Queuesadilla' => [
    'engine' => [
        // yum environment variables
        'url' => env('DATABASE_URL'),
    ],
],
```

If you run the worker now, you'll get the same output as before, only this time it will respect any additional options you give it, as well as application-level changes to the logger or the backing engine.

## Testing the job runner

Now that we have a simple worker going, lets test it with a simple job. Place the following in `src/Job/TestJob.php`:

```php
<?php
namespace App\Job;

class TestJob
{
    public function perform($job)
    {
        debug($job->data());
    }
}
?>
```

Next, we can test this using the `bin/cake console` shell:

```php
// nonsense boilerplate so we can get a logger in the `bin/cake console` shell
$stdout = new \Cake\Log\Engine\ConsoleLog([
    'types' => ['notice', 'info', 'debug'],
    'stream' => new \Cake\Console\ConsoleOutput('php://stdout'),
]);
\Cake\Log\Log::config('stdout', ['engine' => $stdout]);
$logger = \Cake\Log\Log::engine('stdout');

// create an engine
$engine = new \josegonzalez\Queuesadilla\Engine\MysqlEngine(
  $logger,
  ['url' => env('DATABASE_URL')]
);

// create a queue connection
$queue = new \josegonzalez\Queuesadilla\Queue($engine);

// zhu li, queue the thing!
$queue->push(['\App\Job\TestJob', 'perform'], ['sleep' => 3, 'message' => 'hi', 'raise' => false]);
```

If you were running the `bin/cake queue` shell in another terminal, you should have seen the debug output.

---

CakePHP Shells are actually quite powerful. You can use them not only as wrappers of external job running tools, but also as a way to invoke administrative, one-off code as in the `bin/cake console` shell. You could also write longer, one-off tasks as custom shells, and cron-tasks *definitely* belong in them.
