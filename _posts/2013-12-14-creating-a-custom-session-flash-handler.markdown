---
  title:       "Creating a custom session flash handler"
  date:        2013-12-14 15:45
  description: "Using class aliasing is a powerful way to inject custom logic into the CakePHP core without actually rewriting libraries in the CakePHP core."
  category:    cakephp
  tags:
    - aliasing
    - cakeadvent-2013
    - cakephp
    - sessions
  comments:    true
  sharing:     true
  published:   true
  layout:      post
  series:      CakeAdvent-2013
---

One of CakePHP's features is to allow you to override internal Behaviors, Components and Helpers using class aliasing. For instance, one might want to override the internal `FormHelper` to add HTML6 (not a typo) support, and CakePHP would be okay with that:

```php
<?php
App::uses('Controller', 'Controller');
class AppController extends Controller {
  public $helpers = array(
    'Form' => array('className' => 'HTML6'),
  );
}
?>
```

Something I've been doing recently in most of my projects is use Twitter Bootstap for general setup via the [BoostCake plugin](https://github.com/slywalker/cakephp-plugin-boost_cake). It automatically configures CakePHP to use either Bootstrap 2 or 3, and allows me to alias my pertinent helpers to their bootstrappified equivalents.

One thing that is missing is `Session::setFlash()`. It is quite a pain to do the following:

```php
<?php
$this->Session->setFlash('Some error message', 'alert', array(
  'plugin' => 'TwitterBootstrap',
  'class' => 'alert-error'
), 'alert'));
?>
```

Boo. Instead, what if we had the following api?


```php
<?php
$this->Session->alert_error('Some error message');
?>
```

That is *much* nicer looking. We could handle this by adding another method to the AppController, but doing so means copy-pasting between projects. Instead, lets make a custom SessionComponent:

```php
<?php
App::uses('SessionComponent', 'Controller/Component');
class TwitterSessionComponent extends SessionComponent {

  public function __call($name, $args) {
    $method = $name;
    $key = 'flash';

    if (strpos($method, 'form_') === 0) {
      $key = 'form';
      $method = preg_replace('/^form_/', '', $method);
    }

    if (strpos($method, 'alert_') === 0) {
      $method = preg_replace('/^alert_/', '', $method);
    }

    $class = null;
    if (in_array($method, array('success', 'danger', 'error', 'info'))) {
      $class = 'alert-' . $method;
    }

    if ($class !== null || $method === 'alert') {
      $plugin = 'TwitterBootstrap';
      return $this->setFlash($args[0], 'alert', compact('plugin', 'class'), $key);
    }

    throw new BadMethodCallException("Method '{$name}' does not exist.");
  }
}
?>
```

Sweet, we have a custom component that can deal with our code. But rather than use *two* SessionComponents, we can use class name aliasing to load just ours as the default!

```php
<?php
App::uses('Controller', 'Controller');
class AppController extends Controller {
  public $components = array(
    'Auth',
    'Cookie',
    'RequestHandler',
    'Session' => array('className' => 'TwitterSession'),
  );
}
?>
```

Now we can do the following:

```php
<?php
App::uses('AppController', 'Controller');
class UsersController extends AppController {
  public function update_profile() {
    $user_id = $this->Auth->user('id');
    $user = $this->User->find('profile', compact('user_id'));

    try {
      $this->User->updateProfile($user, $this->request->data);
      $this->Session->form_success(__('Your profile has been updated!'));
      $user = $this->User->find('profile', compact('user_id'));
      $this->request->data = $user;
    } catch (Exception $e) {
      $user = $this->User->find('profile', compact('user_id'));
      $this->Session->form_danger($e->getMessage());
    }

    $this->set(compact('user'));
  }
?>
```

Using class aliasing is a powerful way to inject custom logic into the CakePHP core without actually rewriting libraries in the CakePHP core. Try it today!
