---
  title:       "Fun with CakePHP Views"
  date:        2013-12-02 00:00
  description: A guide to creating a custom CakePHP view that generates identicon png images for users
  category:    cakephp
  tags:
    - cakeadvent-2013
    - cakephp
    - identicon
    - views
  comments:    true
  sharing:     true
  published:   true
  layout:      post
  series:      CakeAdvent-2013
---

One of the least used features of CakePHP are custom view classes. Custom view classes allow a developer to specify a set of data for the view and have the output automatically formatted. While this automation comes at a price in terms of application speed, it can have great affect on rapid application development. Server resources are cheap, while development time is not.

CakePHP has a few, built-in view classes:

- [Json/Xml View Classes](http://book.cakephp.org/2.0/en/views/json-and-xml-views.html): useful for building apis.
- [ThemeView Class](http://book.cakephp.org/2.0/en/views/themes.html): useful for application theming (think CMS-type applications). As of 2.1, it is built into the default View class.
- [MediaView Class](http://book.cakephp.org/2.0/en/views/media-view.html): useful for requiring authentication before rendering an asset (though I'd move this into the server if at all possible). As of 2.3, deprecated in favor of CakeResponse::file().
- [Scaffold Class](http://book.cakephp.org/2.0/en/controllers/scaffolding.html): useful for generating quick and dirty admin apps in testing phases.

There are also a few, popular view classes within the community:

- [CakePDF](https://github.com/ceeram/cakepdf): CakePHP plugin for creating and/or rendering Pdf, with several Pdf engines supported.
- [CsvView](https://github.com/josegonzalez/cakephp-csvview): Quickly enable CSV output of your model data, which is quite useful for reporting applications
- [TwigView](https://github.com/predominant/TwigView): Cool integration of Twig to replace the built-in PHP-based view system.

These are all well and good, but you can also do some amazing things with views. Today we'll make a custom view class that shows identicons for a user:

## Scaffolding a View class

Since we don't want to fiddle with creating routes, we'll need to add the ability to parse the `png` extension. The following bit of code can be added to your `routes.php`:

```php
<?php
// at the top
Router::parseExtensions('png');

// your routes here
?>
```

This tells the Router to automatically switch view classes when a request is performed with the `.png` extension.

Our next trick will require telling the `RequestHandler` about our `IdenticonView`. This is done within the controller:

```php
<?php
class AppController extends Controller {
  public $components = array(
    'RequestHandler' => array(
      'viewClassMap' => array(
        'png' => 'Identicon',
      )
    )
  );
}
?>
```

The above code will register the `IdenticonView` class to any requests for `png` files on subclasses. This does mean you will need to allow routing `png` files to your CakePHP application from Nginx or Apache, but that should already be setup ;)

Most view classes use a `_serialize` view variable to show what variable(s) should be used to retrieve data for the custom view. We'll also do this for our view as follows:

```php
<?php
class UsersController extends AppController {
  public function user($username) {
    $user = $this->User->findByUsername($username);
    $this->set('user', $user);
    $this->set('_serialize', array('user'));
  }
}
?>
```

Finally, we'll need to construct our custom view class:

```php
<?php
App::uses('View', 'View');
class IdenticonView extends View {
}
?>
```

And we're done!

## Creating a custom view class

We actually are a bit farther away than you'd expect. First, we'll need to have some code that actually generates an identicon. For our purposes, we'll use the [Identicon](https://github.com/yzalis/Identicon/) PHP library maintained by [YZalis](http://yzalis.com/). You can - and should - install it via [composer](http://getcomposer.org/).

### Error Handling

Next, we'll want to add a little error detection to our class. If an error/exception is somehow thrown, CakePHP's exception handler will catch it and - depending upon your setup, the view class *could* end up recursing this error. We should short-circuit that:

```php
<?php
App::uses('View', 'View');
class IdenticonView extends View {
  public function __construct(Controller $controller = null) {
    parent::__construct($controller);
    $this->response->type('image/png');
    if ($Controller instanceof CakeErrorController) {
      return $this->response->type('html');
    }
  }
}
?>
```

Next, we'll need to handle this switch in your `IdenticonView::render()` class:


```php
<?php
App::uses('View', 'View');
class IdenticonView extends View {
  public function render($view = null, $layout = null) {
    if ($this->response->type() != 'image/png') {
      return parent::render($view, $layout);
    }

    $_serialize = $this->get('_serialize');
    if (!$_serialize) {
      throw new CakeException("No view variable specified");
    }
  }
}
?>
```

The above will switch to the parent `View` class when the response type is not `image/png`. We'll also throw an exception when no view variable is specified int the `_serialize` key.

### Generating images

Assuming we have the identicon class included via Composer, we'll want to now generate the image within our `IdenticonView::render()` method:

```php
<?php
App::uses('View', 'View');
class IdenticonView extends View {
  public function render($view = null, $layout = null) {
    if ($this->response->type() != 'image/png') {
      return parent::render($view, $layout);
    }

    $_serialize = $this->get('_serialize');
    if (!$_serialize) {
      throw new CakeException("No view variable specified");
    }

    // Extract the `email` field from the variable
    $email = null;
    foreach ($_serialize as $data) {
      $email = Hash::get($data, "{s}.email");
      if ($email) {
        break;
      }
    }

    // If no email was found in the _serialize'd data, throw an exception
    if (!$email) {
      throw new CakeException("No email address specified");
    }

    // Set the image to the `content` block
    $identicon = new Identicon();
    $this->Blocks->set('content', $identicon->getImageData($email));
    return $this->Blocks->get('content');
  }
}
?>
```

Presto-chango! We now have a custom view class! Simply make a request to `http://example.com/users/user/derp.png` to see the results!

## What now?

This was a toy view class, but can be used as a model for future view classes. For instance, we might create a View class that generates gamer tags for embedding on your site, or generate SKU images for printing. A *cool* use might be to build a status badge for a particular application - maintenance, up, down, etc. - in some sort of application monitoring system.

View classes are a powerful way to speed up your application development. If you're building something other than HTML output for your application, I suggest looking into how view classes might replace duplicative knowledge.

