---
  title:       "Application-wide event management"
  date:        2013-12-23 14:15
  description: "Triggering global CakePHP events isn't difficult, and this tutorial shows you how to do it."
  category:    CakePHP
  tags:
    - CakeAdvent-2013
    - cakephp
    - events
  comments:    true
  sharing:     true
  published:   true
  layout:      post
  series:      CakeAdvent-2013
---

Today's post is a simple, application-wide event manager. Listening and firing events usually requires some thought as to where the event should be attached. Do we want it on a model? What if I make a custom class? What if I don't have access to something because I am in a plugin?

One thing I do is make a generic event dispatcher that can be used everywhere. Here's how you can do the same.

## AppEventDispatcher

We discussed an `AppEventDispatcher` in a [previous post](/2013/12/16/simpler-cakephp-events/). If you are using that, you can continue doing so. Everything from here will be additive.

First, the `CakeEventManager` has a method `instance()` which returns a globale `CakeEventManager`. This is useful for a global hooks system. We'll use this in our own methods.

To handle the entire cycle, we will use both a `listen` and `fire` method.

- `listen`: Handles the attachment of a listener to the specified event. If the listener is an instance of `EventListener`, event names can be omitted.
- `fire`: Handles the dispatching of a given event. Keep in mind that `$subject` and `$data` are optional arguments to this method.

Here is our `Lib/Event/AppEventDispatcher.php` class with the above methods:

```php
<?php
App::uses('CakeEvent', 'Event');
App::uses('CakeEventManager', 'Event');

class AppEventDispatcher {
  public static function listen($callable, $eventKey = null, $options = array()) {
    $manager = CakeEventManager::instance();
    $manager->attach($callable, $eventKey, $options);
  }

  public static function fire($name, $subject = null, $data = null) {
    $manager = CakeEventManager::instance();
    $event = new CakeEvent($name, $subject, $data);
    $manager->dispatch($event);
    return $event;
  }
}
?>
```

Now that we have our AppEventDispatcher in place, we can start using it.

## Global Startup Events

You may wish to create global events before most of the app has started. We'll create a new file, `app/Config/events.php`, which will contain our events. Include this file in your `app/Config/bootstrap.php`:

```php
<?php
include dirname(__FILE__) . DS . 'events.php';
?>
```

Next, create the file:

```shell
touch app/Config/events.php
```

And we'll add the following as content:

```php
<?php
App::uses('AppEventDispatcher', 'Lib/Event');
App::uses('CakeEvent', 'Event');
?>
```

Now we're ready to test our global event system

## Test the whole thing

Lets add the following to `app/Config/events.php`:

```php
<?php
AppEventDispatcher::listen(function(CakeEvent $event) {
  debug($event->name());
  debug($event->subject());
  debug($event->data);
  die;
}, 'foo');
?>
```

This is the initial setup for a dummy event `foo` that triggers a callback which prints out the event and then exits the app. Not too fantastic, but for the purposes of our demo, it will do.

Now we need to fire the event. While not super exciting, I am placing the following at the bottom of my `app/Config/routes.php` file:

```php
<?php
AppEventDispatcher::fire('foo', null, array('baz'));
?>
```

And if we start our app, here is the output:

![http://cl.ly/image/1Q1O252X323d](http://cl.ly/image/1Q1O252X323d/Screen%20Shot%202013-12-23%20at%202.30.04%20PM.png)

## Going further

The following things are not available in our current implementation:

- Queued events. These events would wait for a `AppEventDispatcher::flush()` before firing.
- Subscriber classes that can be subscribed to any specified event
- Wildcard event names.

Some of the above may be tricky, but all are doable, and if you find them useful, feel free to extend my implementation to include your use cases :)
