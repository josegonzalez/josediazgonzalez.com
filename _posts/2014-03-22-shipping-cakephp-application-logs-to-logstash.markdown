---
  title:       "Shipping CakePHP App Logs to Logstash via Syslog"
  date:        2014-03-22 06:28
  description: If you've never written a CakePHP Logger, here is a simple post on how to do so
  category:    cakephp
  tags:
    - cakephp
    - logging
    - logstash
  comments:    true
  sharing:     true
  published:   true
  layout:      post
---

Writing a logger for CakePHP isn't very difficult. The work lies in implementing the `CakeLogInterface`, which requires that you implement a `write` method as follows:

```php
<?php
App::uses('BaseLog', 'Log/Engine');
class LogstashLog extends BaseLog
{
    public function write($type, $message)
    {
        // write to some output.
    }
}
?>
```

The above class can go into `app/Lib/Log/Engine/LogstashLog.php`. Once you've implemented the interface - and I recommend you do so by extending BaseLog - you may want to actually write the logs to some location. In our case, we want to ship these logs to `Logstash`, a log processing tool that can take logs and decompose them into useful information.

At the very base, log messages should have some context about the logs - specifically a timestamp. Rather than invent our own format, we'll use [ISO-8601](http://en.wikipedia.org/wiki/ISO_8601), which Logstash can handle natively. We can represent this using the following bit of code:

```php
<?php
$format = 'Y-m-d\TH:i:s.uP';
echo date($format); // ISO-8601 compliant datetime
?>
```

Logstash also represents message as `json` in a specific format. Pre-formatting our log messages would allow Logstash to skip any regular expression parsing of our log messages. The following is the current format:

```javascript
{
    "@timestamp": "2012-12-18T01:01:46.092538Z",
    "@version": 1,
}
```

All other fields are optional, and therefore our `LogstashLog` would look as follows:

```php
<?php
App::uses('BaseLog', 'Log/Engine');
class LogstashLog extends BaseLog
{
    protected $format = 'Y-m-d\TH:i:s.uP';
    public function write($type, $message)
    {
        $data = [
            '@timestamp' => date($this->format),
            '@version' => 1,
            'message' => $message,
            'tags' => [$type],
        ];
        // write to some output.
    }
}
?>
```

We can use `syslog` to ship our logs. PHP defines the following three methods to interface with `syslog`, and I recommend reading up on them:

- `openlog`: opens a connection to the system logger for a program
- `syslog`: generates a log message that will be distributed by the system logger
- `closelog`: closes the descriptor being used to write to the system logger

Adding in `syslog` support will change our logger as follows:

```php
<?php
App::uses('BaseLog', 'Log/Engine');
class LogstashLog extends BaseLog
{
    protected $format = 'Y-m-d\TH:i:s.uP';

    protected $logLevels = [
        'emergency' => LOG_EMERG,
        'alert' => LOG_ALERT,
        'critical' => LOG_CRIT,
        'error' => LOG_ERR,
        'warning' => LOG_WARNING,
        'notice' => LOG_NOTICE,
        'info' => LOG_INFO,
        'debug' => LOG_DEBUG,
    ];

    public function write($type, $message)
    {
        $data = [
            '@timestamp' => date($this->format),
            '@version' => 1,
            'message' => $message,
            'tags' => [$type],
        ];

        if (!openlog('app', LOG_PID, LOG_USER)) {
            // Handle your logging error...
            return;
        }

        syslog($this->logLevels[$type], json_encode($data));
    }
}
?>
```

What if we wanted to include extra metadata? Well, we can modify our `write` method to allow `$message` to be an array as follows:

```php
public function write($type, $message)
{
    $message = is_array($message) ? $message : compact('message');
    $data = array_merge(array(
        '@timestamp' => date($this->format),
        '@version' => 1,
    ), $message);

    if (isset($data['tags'])) {
        $data['tags'][] = $type;
    } else {
        $data['tags'] = [$type];
    }

    if (!openlog('app', LOG_PID, LOG_USER)) {
        // Handle your logging error...
        return;
    }

    syslog($this->logLevels[$type], json_encode($data));
}
```

We never want to drop logs, so we'll fallback to using `FileLog` as our parent class. When `openlog` returns false, we'll simply call `return parent::write($type, json_ecode($message));`. We can then later go back with a different log shipper and reprocess anything that couldn't be shipped to Logstash.

Here is what our log engine will look like at the end of the day:


```php
<?php
App::uses('FileLog', 'Log');
class LogstashLog extends FileLog
{
    protected $format = 'Y-m-d\TH:i:s.uP';

    protected $logLevels = [
        'emergency' => LOG_EMERG,
        'alert' => LOG_ALERT,
        'critical' => LOG_CRIT,
        'error' => LOG_ERR,
        'warning' => LOG_WARNING,
        'notice' => LOG_NOTICE,
        'info' => LOG_INFO,
        'debug' => LOG_DEBUG,
    ];

    public function write($type, $message)
    {
        $message = is_array($message) ? $message : compact('message');
        $data = array_merge(array(
            '@timestamp' => date($this->format),
            '@version' => 1,
        ), $message);

        if (isset($data['tags'])) {
            $data['tags'][] = $type;
        } else {
            $data['tags'] = [$type];
        }

        if (!openlog('app', LOG_PID, LOG_USER)) {
            return parent::write($type, json_ecode($data));
        }

        return syslog($this->logLevels[$type], json_encode($data));
    }
}
?>
```

We can now configure our custom logging engine the same way we would any other logging engine:

```php
<?php
// in our app/Config/bootstrap.php
App::uses('CakeLog', 'Log');
CakeLog::config('debug', [
    'engine' => 'Logstash',
    'types' => ['notice', 'info', 'debug'],
    'file' => 'debug',
]);
CakeLog::config('error', [
    'engine' => 'Logstash',
    'types' => ['warning', 'error', 'critical', 'alert', 'emergency'],
    'file' => 'error',
]);
?>
```

You'll notice that we included some extra configuration information. This is primarily used for routing messages - we could in theory create a `Null` engine and use that for `debug` messages - though we also specify a `file` so that the parent `FileLog` class is properly configured.

Creating custom logging engines is quite simple with CakePHP, and it would be easy to extend this system to have log handlers and formatters.
