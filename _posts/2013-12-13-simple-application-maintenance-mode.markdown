---
  title:       "Simple application maintenance mode"
  date:        2013-12-13 03:05
  description: "Setup a fast maintenance mode for your application using the CakePHP Dispatch Filter system"
  category:    cakephp
  tags:
    - dispatcher
    - cakeadvent-2013
    - cakephp
    - maintenance
  comments:    true
  sharing:     true
  published:   true
  layout:      post
  series:      CakeAdvent-2013
---

If you need a simple application maintenance mode, fear not! CakePHP has you covered!

We'll need to create a custom Dispatch Filter:

```php
<?php
// In Lib/Routing/Filter/MaintenanceMode.php
App::uses('DispatcherFilter', 'Routing');
class MaintenanceMode extends DispatcherFilter {
  public function beforeDispatch(CakeEvent $event) {
    if (!Configure::read('MaintenanceMode.enabled')) {
      return;
    }

    $event->data['response']->statusCode(503);
    $event->data['response']->body('503 Service Unavailable');
    $event->stopPropagation();
    return $event->data['response'];
  }
}
?>
```

Now we can attach it to our existing dispatch filters:

```php
<?php
// in our bootstrap.php
App::uses('MaintenanceMode', 'Lib/Routing/Filter');
Configure::write('Dispatcher.filters', array(
  'AssetDispatcher',
  'CacheDispatcher',
  'MaintenanceMode', // our new filter here!
));
?>
```

Tada! Now turning on maintenance mode is as simple as `Configure::write('MaintenanceMode.enabled', 1)`!

## Using custom views

The above is lame in that it only works for a simple 503 error page. What if you want to use a custom status code, or maybe a custom view file?

To do this, lets change our filter a bit:

```php
<?php
// In Lib/Routing/Filters/MaintenanceMode.php
App::uses('DispatcherFilter', 'Routing');
class MaintenanceMode extends DispatcherFilter {
  public function beforeDispatch(CakeEvent $event) {
    if (!Configure::read('MaintenanceMode.enabled')) {
      return;
    }
    $statusCode = Configure::read('MaintenanceMode.code');
    $statusMessage = Configure::read('MaintenanceMode.message');
    if (!$statusCode) {
      $statusCode = 503;
      $statusMessage = '503 Service Unavailable';
    }

    if (!$statusMessage) {
      $statusMessage = $statusCode . ' Currently undergoing maintenance';
    }

    $event->data['response']->statusCode($statusCode);
    $event->data['response']->body($statusMessage);
    $event->stopPropagation();
    return $event->data['response'];
  }
}
?>
```

At this point, we can configure a custom status code and a custom message. Lets add the ability to use a custom view:

```php
<?php
  protected function _getView() {
    $helpers = Configure::read('MaintenanceMode.helpers');
    if (empty($helpers) || !is_array($helpers)) {
      $helpers = array('Html');
    }
    $View = new View(null);
    $View->viewVars = Configure::read('MaintenanceMode');
    $View->helpers = $helpers;
    $View->loadHelpers();
    $View->hasRendered = false;
    $View->viewPath = 'MaintenanceMode';
    return $View;
  }
?>
```

We'll need to modify our `beforeDispatch`, where we set the response body:

```php
<?php
    $template = Configure::read('MaintenanceMode.template');
    if ($template) {
      $View = $this->_getView();
      $body = $View->render($template, Configure::read('MaintenanceMode.layout'));
      $event->data['response']->body($body);
    } else {
      $event->data['response']->body($statusMessage);
    }
?>
```

And add the `App::uses('View', 'View');` call to the top of your `MaintenanceMode` class. Now to use a custom view, we'd create a file in `app/View/MaintenanceMode/index.ctp` with our content, a `app/View/MaintenanceMode/maintenance.ctp` layout, and then configure our filter as follows:

```php
<?php
Configure::write('MaintenanceMode', array(
  'enabled' => true,
  'helpers' => 'Html',
  'layout' => 'maintenance',
  'template' => 'index'
));
?>
```

You can extend this as far as you need, and here are a couple of ideas:

- Add ajax request support
- Enable custom view classes
- Allow maintenance mode to be enabled via the existence of a file, or an environment variable
- Have this affect background processes
- Add unit tests!

If you need some downtime this Christmas, CakePHP has your back!
