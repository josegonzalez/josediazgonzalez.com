---
  title:       "Custom Logging Engines and adding Contextual Data"
  date:        2015-12-14 12:00
  description: "Silly hacks you can use in your cakephp applications"
  category:    cakephp
  tags:
    - cakeadvent-2015
    - cakephp
    - logging
  comments:    true
  sharing:     true
  published:   true
  layout:      post
  series:      CakeAdvent-2015
---

Logging is incredibly important, and are very useful for debugging misbehaving applications. CakePHP 3 implements the [PSR-3](https://github.com/php-fig/log) logging standard - specifically extending the [AbstractLogger](https://github.com/php-fig/log/blob/master/Psr/Log/AbstractLogger.php) - so you have all normal logging levels available:

```php
// the `Cake\Log\Log` class holds a log registry,
// so you don't need to instantiate new loggers constantly
Log::info('Some info level message');
Log::error('uh oh! an error');

// Swap out to Monolog because you need
// to ship/store logs a specific way
// In your bootstrap:
use Monolog\Logger;
use Monolog\Handler\StreamHandler;

// Configure the logger
Log::config('default', function () {
    $log = new Logger('app');
    $log->pushHandler(new StreamHandler('path/to/your/combined.log'));
    return $log;
});

// Drop unused loggers
Log::drop('debug');
Log::drop('error');
// and then use it as normal
```

You'll notice that a few classes have their own `log` methods. You can add this to your own classes using the `LogTrait`:

```php
<?php
namespace App;

use Cake\Log\LogTrait;
class Foo {
  use LogTrait
  public function bar()
  {
    $this->log('baz');
  }
}
?>
```

One thing I like doing is having `Tagged` logs. That is, I will write a log message like so:

```php
// Message is an entity WUT
// Entities are just bags of data, you can use them however you want
$message = new Message([
  'message' => 'User logged in',
  'user_id' => $user->get('id'),
  'via' => 'android'
]);

// :boom:
Log::info($message);
```

CakePHP's internal formatter will automatically `json_encode` any message that is `JsonSerializable`. If you also implement a `__toString()` method, that will be used instead.

This is kinda shoddy though, especially needing to manually pass in information that can be inferred through the request. Another method is to pass in that extra data as part of the context of a log message:

```php
Log::info('User logged in', ['request' => $request, 'user' => $user]);
```

But this extra data is usually ignored. CakePHP's internal logging doesn't have the concept of a formatter - that's something we'd prefer you use a full logging package like [Monolog](https://github.com/Seldaek/monolog) for - but you *can* easily implement your own `LogEngine` that does what you need. Here is a simple one that simply logs to a file with our extra data:

```
<?php
namespace App\Log\Engine;
use Cake\Log\Engine\FileEngine;
class ContextFileEngine
{
  public function _format($data, $context)
  {
    if (is_string($data)) {
      return $this->_injectContext($data, $context)
    }

    $object = is_object($data);

    if ($object && method_exists($data, '__toString')) {
      $data = (string)$data;
      return $this->_injectContext($data, $context)
    }

    if ($object && $data instanceof JsonSerializable) {
      $data = json_decode(json_encode($data), true);
      return $this->_injectContext($data, $context)
    }

    return $this->_injectContext(print_r($data, true), $context);
  }

  protected function _injectContext($message, $context)
  {
    $via = null;
    $userId = null;
    if (!empty($context['request'])) {
      $via = $context['request']->header('X-Client');
    }
    if (!empty($context['user'])) {
      $userId = $context['user']->get('id');
    }

    $data = compact('message', 'via', 'userId');
    // handle arrays
    if (is_array($message)) {
      $data = $message + compact('via', 'userId');
    }

    return parent::_format(json_encode($data), $context);
  }
}
?>
```

The above will have output similar to the following:

```
2015-12-14 7:55:00 INFO: {"message": "User logged in", "userId": 7, "via": "android"}
```

This method of injecting contextual data into your logs is quite useful for later debugging, and doesn't require too much extra work around how logs are actually written. Of course, if you need more powerful logging features, I wholeheartedly recommend looking into [Monolog](https://github.com/Seldaek/monolog)
.
