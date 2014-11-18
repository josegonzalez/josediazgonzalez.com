---
  title:       "Hacking the CakePHP Dispatch System"
  date:        2013-12-03 00:13
  description: "Wherein we abuse the CakePHP Disptach cycle to remove the Controllers and Views from our application in favor of smaller, testable units of code. One weird trick, APIs loves this!"
  category:    CakePHP
  tags:
    - CakeAdvent-2014
    - cakephp
    - dispatcher
  comments:    true
  sharing:     true
  published:   true
  layout:      post
  series:      CakeAdvent
---

People always complain about CakePHP being slow, so what if we just removed a few layers from the CakePHP MVC?

The smallest CakePHP application - that is maintainable - would be introduced in the `bootstrap.php` file. It would be a Dispatch Filter:

```php
<?php
App::uses('DispatcherFilter', 'Routing');
class ModelFilter extends DispatcherFilter {
  public function beforeDispatch(CakeEvent $event) {
    $event->data['response']->body('Hello World');
    $event->stopPropagation();
    return $event->data['response'];
  }
}
?>
```

The above is a slightly modified version of the [HelloWorldFilter](http://book.cakephp.org/2.0/en/development/dispatch-filters.html) from the CakePHP documentation. We would configure it as follows in the application's `bootstrap.php`:

```php
<?php
Configure::write('Dispatcher.filters', array(
    'ModelFilter',
));
?>
```

> Please note that there are other filters - `AssetDispatcher` and `CacheDispatcher` - that must also be configured if CakePHP is to respond correctly to reqests. Whether they are before or after the filters in this post is up to you.


Once configured, we would respond to all requests with `Hello World`.  Lets assume we have custom find methods that retrieve the model data appropriately for index/view actions, and we only wish to route those:

```php
<?php
App::uses('DispatcherFilter', 'Routing');
class ModelFilter extends DispatcherFilter {
  public function beforeDispatch(CakeEvent $event) {
    $request = $event->data['request'];
    if (!in_array($request->action, array('index', 'view'))) {
      return;
    }

    $event->data['response']->body('Hello World');
    $event->stopPropagation();
    return $event->data['response'];
  }
}
?>
```

The next step would be to actually call the model finds. Easy enough, using `ClassRegistry::init()`:

```php
<?php
App::uses('DispatcherFilter', 'Routing');
class ModelFilter extends DispatcherFilter {
  public function beforeDispatch(CakeEvent $event) {
    $request = $event->data['request'];
    if (!in_array($request->action, array('index', 'view'))) {
      return;
    }

    $modelClass = Inflector::classify($request->controller);
    App::uses('ClassRegistry', 'Utility');
    App::uses($modelClass, 'Model');
    $posts = ClassRegistry::init($modelClass);
    try {
      $posts = $posts->find($request->action);
      $body = array('status' => 'success', 'data' => $posts);
    } catch (Exception $e) {
      $event->data['response']->statusCode(400);
      $body = array('status' => 'error', 'message' => $e->getMessage());
    }

    $event->data['_body'] = $body;
  }
}
?>
```

The above doesn't appear to do anything. We didnt modify the response because the purpose of this filter was simply to retrieve data for the response, not to *set* the response. Lets do that now.

## Modifying the response

We'll want to add another filter to the dispatch cycle:

```php
<?php
Configure::write('Dispatcher.filters', array(
    'ModelFilter',
    'JsonFilter'
));
?>
```

Now lets build a simple `JsonFilter`. It will be triggered *after* the `ModelFilter`, and as such should check to see if there is a `_body` in the event data:



```php
<?php
App::uses('DispatcherFilter', 'Routing');
class JsonFilter extends DispatcherFilter {
  public function beforeDispatch(CakeEvent $event) {
    if (empty($event->data['_body'])) {
      return;
    }

    $event->data['response']->body('Hello World');
    $event->stopPropagation();
    return $event->data['response'];
  }
}
?>
```

Lets also assume that we need to only process json requests. For this, you'll need to add the following to the top of your `routes.php` file:

```php
<?php
Router::parseExtensions('json');
?>
```

And our final `JsonFilter` would look like:


```php
<?php
App::uses('DispatcherFilter', 'Routing');
class JsonFilter extends DispatcherFilter {
  public function beforeDispatch(CakeEvent $event) {
    $request = $event->data['request'];
    if (empty($event->data['_body']) || $request->param('ext') != 'json') {
      return;
    }

    $event->data['response']->body(json_encode($event->data['_body']));
    $event->stopPropagation();
    return $event->data['response'];
  }
}
?>
```

And here is the final response:

![http://cl.ly/image/1P2b3c3z3i3z](http://f.cl.ly/items/3B1H3q3i2g3S3i2n2r05/Screen%20Shot%202013-12-03%20at%2012.07.49%20AM.png)

## Adding a bit of *flavour*

What if we wanted to support something other than json? Lets support [Message Pack](http://msgpack.org/)!

First, install the pecl extension:

```bash
pecl install msgpack
```

And now we can add a new filter:

```php
<?php
Configure::write('Dispatcher.filters', array(
    'ModelFilter',
    'JsonFilter',
    'MessagePackFilter',
));
?>
```

And ensure the routing system handles the new extension:

```php
<?php
Router::parseExtensions('msgpack');
?>
```

And the code:

```php
<?php
App::uses('DispatcherFilter', 'Routing');
class MessagePackFilter extends DispatcherFilter {
  public function beforeDispatch(CakeEvent $event) {
    $request = $event->data['request'];
    if (empty($event->data['_body']) || $request->param('ext') != 'msgpack') {
      return;
    }

    $event->data['response']->body(msgpack_pack($event->data['_body']));
    $event->stopPropagation();
    return $event->data['response'];
  }
}
?>
```

Instant message pack support!

## Adding a bit of authentication spice

Lets say we want some dead simple authentication in front of this. We just want to ensure users without the magic key do not get access to our super-webscale json/msgpack api.

They'll need to set the following header on their requests:

```bash
curl -h 'Crappy-Auth: herp:derp' http://example.com/posts/index.json
```

Doing the above would be *trivial*. Lets setup a new filter. It needs to run after our `ModelFilter`, since we only want to trigger it in the case where the `ModelFilter` runs:


```php
<?php
Configure::write('Dispatcher.filters', array(
    'ModelFilter',
    'CrappyAuthFilter',
    'JsonFilter',
    'MessagePackFilter',
));
?>
```

And here is our authentication filter:

```php
<?php
App::uses('DispatcherFilter', 'Routing');
class CrappyAuthFilter extends DispatcherFilter {
  public function beforeDispatch(CakeEvent $event) {
    $request = $event->data['request'];
    if (empty($event->data['_body'])) {
      return;
    }

    $auth = $request->header('Crappy-Auth');
    if ($auth == 'herp:derp') {
      return;
    }

    $event->data['response']->statusCode(401);
    $event->data['_body'] = array('status' => 'error', 'message' => 'Unauthorized');;
    return $event->data['response'];
  }
}
?>
```

And now we've added some trivial authentication to our api.

![http://cl.ly/image/0e0p0y0z2u0D](http://f.cl.ly/items/2N1j3J0L0M3k4347422v/Screen%20Shot%202013-12-03%20at%2012.27.14%20AM.png)

## Why??!!?

If you are looking to trim the fat from your CakePHP application - and potentially break some benchmark records - dispatch filters are a cool way to do so. For applications where the majority of the logic is a model-layer action + authentication, they provide a cheap way of getting speed gains while still keeping applications modular and testable.

Props goes to [Jose Lorenzo](https://twitter.com/jose_zap) for his initial presentation on this sort of method at the 2010 Chicago Cakefest. He used custom route classes, which is something I later prototyped for the [dispatch system in 2.x as middlewhare](http://bin.cakephp.org/view/182820021), but the basic concept is the same.

Go forth and CakePHP!
