---
  title:       "CakePHP as a Microframework"
  date:        2014-03-23 20:37
  description: "Using CakePHP as a library to build applications microframework-style"
  category:    CakePHP
  tags:
    - cakephp
    - dispatcher
    - microframeworks
  comments:    true
  sharing:     true
  published:   true
  layout:      post
---

One of the features that most frameworks toute is the ability to respond to a request from the route file immediately. For instance, here is how SlimPHP applications are structured (at least initially):

```php
<?php
$app = new \Slim\Slim();
$app->get('/hello/:name', function ($name) {
    echo "Hello, $name";
});
$app->run();
?>
```

>People familiar with this type of application are likely familiar with the `Sinatra` microframework.

CakePHP has typically been in the opposite camp. Lots of classes to wire up to get a response on the page. Kind of lame, and then you *have* to integrate with CakePHP's conventions, which can be frustrating if you simply want to use the framework as a library. It's quite straightforward to turn CakePHP into a microframework using dispatch filters.

Lets define a simple api. We'll want to be able to connect arbitrary routes to a `callable` or a class that has a `respond` method. This can look like the following:

```php
<?php
class ResponseInterface {
    public abstract function respond($request, $response);
}

class HelloWorld implements ResponseInterface {
    public function respond($request, $response) {
        $response->body('Hello World');
    }
}

Router::connect('/hello/*', ['callable' => function($request, $response) {
    $response->body('Hello World');
}]);

Router::connect('/world/*', ['callable' => 'HelloWorld']);
?>
```

Controller classes have plumbing to auto-generate responses based on *just* the `CakeRequest` and `CakeResponse` objects, hence why they are necessary. We also implement the `ResponseInterface` class to make the PHPJava people happy :)

To route these properly, we'll hook into CakePHP's dispatch cycle using a custom dispatch filter as follows:

```php
<?php
App::uses('DispatcherFilter', 'Routing');
class CallableFilter extends DispatcherFilter {
    public function beforeDispatch(CakeEvent $event) {
        $callable = null;
        if (isset($event->data['request']->params['callable'])) {
            $callable = $event->data['request']->params['callable'];
        }

        if (is_string($callable) && class_exists($callable)) {
            $callable = new $callable;
            $callable->respond($event->data['request'], $event->data['response']);
        } elseif (is_callable($callable)) {
            $callable($event->data['request'], $event->data['response']);
        } else {
            return null;
        }

        $event->stopPropagation();
        return $event->data['response'];
    }
}
?>
```

In our CallableFilter, we check for the existence of a `callable`. For practicality, we're a bit flexible in this definition and also allow class names to be "callables". All `callable` executions are given `CakeRequest` and a `CakeResponse` objects, and we automatically call `$event->stopPropagation()` should the callable be invoked.

To configure our filter, simply attach it to your DispatcherFilter configuration in `app/Config/bootstrap.php` like so:

```php
<?php
Configure::write('Dispatcher.filters', [
    'AssetDispatcher',
    'CacheDispatcher',
    'CallableFilter'
]);
?>
```

And voila! You have a CakePHP microframework.

Some things you can now do with this setup:

- Configure before and after request filters
- Setup a templating system (with helper loading)
- Automatically load model classes based on class name and configuration
- Figure out how to do reverse routing
- Reimplement all of the CakePHP dispatching because you refuse to use a full framework ;)

Microframeworks have their place, and while I don't recommend you implement *all* of your CakePHP applications using the above setup, it can be a powerful tool in your arsenal.
