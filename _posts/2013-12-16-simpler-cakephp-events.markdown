---
  title:       "Simpler CakePHP Events"
  date:        2013-12-16 18:15
  description: "Making small changes to the event system workflow to enhance your productivity through annotations and simpler dispatching!"
  category:    cakephp
  tags:
    - annotations
    - cakeadvent-2013
    - cakephp
    - events
  redirects:
    - /2013/12/15/simpler-cakephp-events/
  comments:    true
  sharing:     true
  published:   true
  layout:      post
  series:      CakeAdvent-2013
---

> This tutorial assumes you are using the FriendsOfCake/app-template project with Composer. Please see [this post for more information](http://josediazgonzalez.com/2013/12/08/composing-your-applications-from-plugins/).

There is always a lot of boilerplate involved in creating a proper event listening setup. Martin Bean [wrote a small tutorial](http://martinbean.co.uk/blog/2013/11/22/getting-to-grips-with-cakephps-events-system/) on it's usage, and I'd like to propose a few small changes:

## Centralized Event Dispatching

One of my complaints with dispatching events is all the complications with figuring out *how* to dispatch. Several classes are involved and I am lazy. Instead, we'll create an `app/Lib/Event/AppEventDispatcher.php`:

```php
<?php
App::uses('CakeEvent', 'Event');
class AppEventDispatcher {
  public static function dispatch($name, $subject, $data = null) {
    $manager = $subject->getEventManager();
    $event = new CakeEvent($name, $subject, $data);
    return $manager->dispatch($event);
  }
}
?>
```

Our sole requirement is that the subject of the event *must* also have a method `getEventManager` that returns a `CakeEventManager` instance. Now the interface becomes:

```php
<?php
App::uses('AppEventDispatcher', 'Lib/Event');
class User extends AppModel {
  public function afterSave($created, $options = array()) {
    if ($created) {
      AppEventDispatcher::dispatch('Model.User.created', $this, array(
        'id' => $this->id,
        'data' => $this->data[$this->alias]
      ));
    }
  }
}
?>
```

Not a big change, but something that removes some complication for me.

## Annotations for custom CakeEventListener

> This section requires Traits, which are only available in 5.4

I absolutely *hate* defining a new method in my listeners to return implemented events. Instead, I'll use annotations. Let's install an annotations library using `composer`:

```shell
composer require minime/annotations:~1.1
```

And now we'll define an `AppEventListener` that all our classes will inherit from:

```php
<?php
App::uses('CakeEventListener', 'Event');
class AppEventListener implements CakeEventListener {

  use Minime\Annotations\Traits\Reader;

  public function implementedEvents() {
    $methods = get_class_methods($this);
    $events = array();
    foreach ($methods as $method) {
      $annotations = $this->getMethodAnnotations($method);
      if (!$annotations->get('CakeEvent')) {
        continue;
      }
      $events[$annotations->get('CakeEvent')] = $method;
    }
    return $events;
  }
}
?>
```

Now we can define a new listener using annotations:

```php
<?php
App::uses('AppEventListener', 'Event');
class UserListener extends AppEventListener {

  /**
   * @CakeEvent Model.User.created
   */
  public function sendActivationEmail(CakeEvent $event) {
      // TODO
  }
}
?>
```

Whenever this listener is used, we iterate over every method and check for the `@CakeEvent` annotation. If it exists, we attach the method to the specified event name.

> This may break if CakePHP ever uses @CakeEvent internally for phpdocs, but that is unlikely as CakePHP doesn't use annotations for code anywhere, nor does it use non-standard annotations for docblocks.

If you are worried about performance hits because of the above method - and you should always be wary when magic is involved - you can cache the implemented events using somthing like APC or a local Memcache instance.

## Properly attaching your listeners

The annoying bit of attaching listeners is that you don't know *where* they should be attached. Attaching in bootstrap for models that aren't going to be used in the request is annoying. Methods I use are as follows:

### Attaching in the constructor

Simply never attach the listener unless the object is constructed. For instance, here is what it would look like in our `app/Model/User.php` model class:

```php
<?php
App::uses('UserListener', 'Event');
class User extends AppModel {
  public function __construct($id = false, $table = null, $ds = null) {
    parent::__construct($id, $table, $ds);
    $this->getEventManager()->attach(new UserListener());
  }
}
?>
```

All you need to do is remember to call the `parent::__construct()` method with the proper arguments.

### Attaching on the fly

My `AppEventDispatcher` normally has the following method:

```php
<?php
App::uses('CakeEvent', 'Event');
class AppEventDispatcher {
  public static function attach($subject, $listenerClass) {
    return $subject->getEventManager()->attach(new $listenerClass);
  }
}
?>
```

Before I expect my code to be called, I would call the following:

```php
<?php
class User extends AppModel {
    public function afterSave($created, $options = array()) {
    if ($created) {
      AppEventDispatcher::attach($this, 'UserListener');
      AppEventDispatcher::dispatch('Model.User.created', $this, array(
        'id' => $this->id,
        'data' => $this->data[$this->alias]
      ));
    }
  }
}
?>
```

Note, this is *quite* messy as nor you are attaching listeners in random places.

### Combine the listener with your class

This one is a combination of the above methods. We'll use the User model as an example. Lets setup our AppModel scaffolding:

```php
<?php
App::uses('AppEventDispatcher', 'Event');
class AppModel extends Model implements CakeEventListener {
  use Minime\Annotations\Traits\Reader;

  public function __construct($id = false, $table = null, $ds = null) {
    parent::__construct($id, $table, $ds);
    $this->getEventManager()->attach($this);
  }
}
?>
```

We've made our model implement the `CakeEventListener`, as well as included the `Minime\Annotations\Traits\Reader` trait. Now lets implement the interface:

```php
<?php
  public function implementedEvents() {
    $methods = $this->getClassMethods($this);

    $events = array();
    foreach ($methods as $method) {
      $annotations = $this->getMethodAnnotations($method);
      if (!$annotations->get('CakeEvent')) {
        continue;
      }
      $events[$annotations->get('CakeEvent')] = $method;
    }
    return array_merge(parent::implementedEvents(), $events);
  }

  public function getClassMethods() {
    $class = get_class($this);
    $classMethods = get_class_methods($class);
    if ($parentClass = get_parent_class($class)) {
        $parentMethods = get_class_methods('Model');
        $readerMethods = get_class_methods('Minime\Annotations\Traits\Reader');
        return array_diff($classMethods, $parentMethods, $readerMethods, array(
          'implementedEvents',
          'getClassMethods'
        ));
    }
    return (array) $classMethods;
  }
?>
```

We have customized our call to get the class methods in order to remove all of the parent methods from the Model as well as the trait that is in use. Note that this allows us to annotate methods in our AppModel. Now we add our event to the `app/Model/User.php` class:

```php
<?php
class User extends AppModel {
  /**
   * @CakeEvent Model.User.created
   */
  public function sendActivationEmail(CakeEvent $event) {
      // TODO
  }
?>
```

And we're done. To implement more events, you simply add the method to your model and annotate it as we did before. You can still attach new listeners, and we are respecting all core events.

## Going further

There are a bunch of small ways you can improve your CakePHP experience. You should not ignore features you want only because CakePHP does not include some library, pattern, or methodology in it's core. We've implemented annotations in a clean way, trimmed the fat off creating new events, and exposed the power of extending CakePHP!
