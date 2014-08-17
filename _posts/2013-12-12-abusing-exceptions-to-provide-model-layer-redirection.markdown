---
  title:       "Abusing Exceptions to provide model-layer redirection"
  date:        2013-12-12 03:01
  description: "Fat models and skinny controllers are about more than data handling. You should also concern yourself with Error state handling and how to bubble up exceptions."
  category:    CakePHP
  tags:
    - cakephp
    - exceptions
    - redirect
  comments:    true
  sharing:     true
  published:   true
  layout:      post
  series:      CakeAdvent
---

Every so often, I wish to both raise an exception to the UI as well as redirect to a specific page on the site. Normally, I'll have code that looks like the following:

```php
<?php
class PostsController extends AppController {
  public function view($id) {
    try {
      $post = $this->Post->findById($id);
    catch (MissingPost $e) {
      $this->Session->setFlash("No post available");
      return $this->redirect('posts/index');
    } catch (NoPostPermissions $e) {
      $this->Session->setFlash("You can't view this");
      return $this->redirect('users/home');
    } catch (UnapprovedPost $e) {
      return $this->redirect('posts/index');
    } catch (Exception $e) {
      $this->Session->setFlash($e->getMessage());
      return $this->redirect('posts/index');
    }
    $this->set(compact('post'));
  }
}
?>
```

The biggest issues here are setting session flash messages and handling the redirects. To handle custom redirects from exceptions, we'll likely want to create a custom exception class where we can attach routing data:

```php
<?php
//  app /Lib/Exception/AppException.php
class AppException extends CakeException {
  public function setRoute($route = null) {
    $this->_attributes['route'] = $route;
  }

  public function getRoute() {
    return $this->_attributes['route'];
  }

  public function hasRoute() {
    return isset($this->_attributes['route']);
  }
}
?>
```

Whenever we wish to use this exception, we simply do the following:

```php
<?php
App::uses('AppException', 'Lib/Exception');
$exception = new AppException("Some error occurred");
$exception->setRoute('account/index');
throw $exception;
?>
```

Note: This isn't very fluent api. A possible solution would be to do something like:

```php
<?php
//  app /Lib/Exception/AppException.php
class AppException extends CakeException {
  public function __construct($message, $code = 0) {
    parent::__construct($message, $code);
    return $this;
  }

  public function setRoute($route = null) {
    $this->_attributes['route'] = $route;
    return $this;
  }

  public function getRoute() {
    return $this->_attributes['route'];
  }

  public function hasRoute() {
    return isset($this->_attributes['route']);
  }
}
?>
```
and then simply do `throw new AppException("Some error message")->setRoute('account/index');`.

Next, you'll want to create a custom `ErrorHandler`. CakePHP allows you to override the built-in one, and while we want most of the original internals, we'll override for our very own exception:

```php
<?php
App::uses('AppException', 'Lib/Exception');
App::uses('ErrorHandler', 'Error');

class AppErrorHandler extends ErrorHandler {

 public static function handleException(Exception $exception) {
   if ($exception instanceof AppException) {
     $element = 'default';
     $message = $exception->getMessage();
     $params = array('class' => 'error');
     CakeSession::write('Message.flash', compact('message', 'element', 'params'));
     if ($exception->hasRoute()) {
       $controller = self::_getController($exception);
       return $controller->redirect($exception->getRoute());
     }
   }

   return parent::handleException($exception);
 }

/**
 * Get the controller instance to handle the exception.
 * Override this method in subclasses to customize the controller used.
 * This method returns the built in `CakeErrorController` normally, or if an error is repeated
 * a bare controller will be used.
 *
 * @param Exception $exception The exception to get a controller for.
 * @return Controller
 */
  protected static function _getController($exception) {
    App::uses('CakeErrorController', 'Controller');
    if (!$request = Router::getRequest(true)) {
      $request = new CakeRequest();
    }
    $response = new CakeResponse(array('charset' => Configure::read('App.encoding')));
    try {
      if (class_exists('AppController')) {
        $controller = new CakeErrorController($request, $response);
      }
    } catch (Exception $e) {
    }
    if (empty($controller)) {
      $controller = new Controller($request, $response);
      $controller->viewPath = 'Errors';
    }
    return $controller;
  }

}
?>
```

Now that this is available, lets configure it in our `core.php`:

```php
<?php
App::uses('AppErrorHandler', 'Lib/Exception');
App::uses('AppException', 'Lib/Exception');
Configure::write('Exception', array(
 'handler' => 'AppErrorHandler::handleException',
  'renderer' => 'ExceptionRenderer',
  'log' => true
));
?>
```

And presto! Now you can throw exceptions with custom routes associated! Now you can start doing the following:

```php
<?php
class NoPostPermissions extends AppException {
  public function __construct($message, $code = 0) {
    $message = "You can't view this";
    parent::__construct($message, $code);
    $this->setRoute('users/home');
    return $this;
  }
}
?>
```

And our above example controller with weird exception handling now becomes:

```php
<?php
class PostsController extends AppController {
  public function view($id) {
    $post = $this->Post->findById($id);
    $this->set(compact('post'));
  }
}
?>
```

Simplify your exception handling logic in controllers today!
