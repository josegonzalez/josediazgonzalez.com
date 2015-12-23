---
  title:       "Tracking Requests Via Dispatch Filters"
  date:        2015-12-19 12:00
  description: "Silly hacks you can use in your cakephp applications"
  category:    cakephp
  tags:
    - cakeadvent-2015
    - cakephp
    - dispatch-filters
    - statsd
  comments:    true
  sharing:     true
  published:   true
  layout:      post
  series:      CakeAdvent-2015
---

CakePHP 2 added dispatch filters. These were cool, but there were a few problems:

- They were managed to configure, which meant it was harder for dependencies and configuration to be added/removed to middleware as the configuration was managed away from the actual dispatch cycle.
- `Configure`-based management makes it harder to reason about when a particular dispatch filter will be hit.
- Because of the above, controller handling had to be outside of the middleware layer. Sometimes you want to do something special, and in our case you basically had to replace the whole Dispatcher to do that. Boo.

In CakePHP 3 we now have a nice stack of middleware you configure in `config/bootstrap.php` using the `DispatcherFactory`. Many applications have no need to modify the stack, but they can be quite handy in a pinch. For instance, what if you wanted to track the number of times certain controller/action pairs in your application are requested?

## Metrics tracking via StatsD

I'm not going to get too much into StatsD, except to say it's a way to track metrics in a time-series database software called graphite. [Here](https://codeascraft.com/2011/02/15/measure-anything-measure-everything/) is a blog post by Etsy covering StatsD and why it's awesome.

In our case, we're going to send a counter to StatsD every time a controller/action pair is hit. Let's install a library to handle talking to statsd:

```shell
composer require league/statsd
```

Next, we'll wire up the simplest of dispatch filters. We will be tracking requests *after* they happen, in case anything happens during the dispatch cycle that would change what would be requested:

```php
<?php
namespace App\Routing\Filter;

use Cake\Event\Event;
use Cake\Routing\DispatcherFilter;
use Cake\Utility\Inflector;
use League\StatsD\Client;

class StatsdFilter extends DispatcherFilter
{
    // only create the client once and
    // keep a reference to it
    protected $client;

    // these can be overriden whenever
    // we add the dispatch filter
    protected $_defaultConfig = [
        'host' => '127.0.0.1',
        'port' => 8125,
        'namespace' => 'app'
    ];
    public function __construct($config = [])
    {
        // ensure configuration is set
        parent::__construct($config);

        $this->client = new Client();
        $this->client->configure([
            'host' => $this->config('host'),
            'port' => $this->config('port'),
            'namespace' => $this->config('namespace'),
        ]);
    }

    public function afterDispatch(Event $event)
    {
        $request = $event->data['request'];
        $response = $event->data['response'];

        // Graphite uses folders for metrics
        // We dasherize the names to keep all metrics sane-looking
        $controller = Inflector::dasherize($response->params['controller']);
        $action = Inflector::dasherize($response->params['action']);
        $statusCode = $response->statusCode();

        // track controller/action pairs
        $statsd->increment(sprintf('web.%s.%s.hit', $controller, $action));

        // track response codes for those pairs as well
        $statsd->increment(sprintf('web.%s.%s.%d', $controller, $action, $statusCode));
    }
}
?>
```

And configuring it is easy. Simply add the following to your `config/bootstrap.php` after the `DispatcherFactory:add('ControllerFactory')` call:

```php
DispatcherFactory::add('StatsdFilter', [
    'host' => '127.0.0.1',
]);
```

And now you'll be tracking metrics in StatsD!

The [docs on dispatch filters](http://book.cakephp.org/3.0/en/development/dispatch-filters.html) have another example - altering cache headers on certain requests - but it should be fairly easy to come up with useful ways of bending dispatch filters to your will!
