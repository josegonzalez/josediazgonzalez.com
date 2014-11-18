---
  title:       "Objectifying CakePHP 2.0 applications"
  date:        2013-12-05 12:59
  description: "Stop complaining about not being able to use objects in the ORM and use 3.0-like features in your 2.0 application today!"
  category:    CakePHP
  tags:
    - CakeAdvent-2014
    - cakephp
    - objects
    - orm
  comments:    true
  sharing:     true
  published:   true
  layout:      post
  series:      CakeAdvent
---

One "failing" CakePHP has is it's use of arrays in the Model layer. I say that in quotes because I do believe using arrays in PHP to represent data is the easy choice, and makes a lot of sense in terms of not slowing down data manipulation. In any case, everyone can agree that objects are a good thing, which is why we are moving the Model layer to objects in 3.0.

One issue with this is that it's difficult to get a sense of how that might affect your CakePHP applications. Many PHP developers have written applications with other frameworks, so they understand what to place where, but there will still be some confusion as to where to place certain methods. Lets take a look at what that might look like in a 2.0 application.

## New classes

In 3.0, there are now `Table` and `Entity` classes. A table represents a collection of objects, and we can use it to represent a collection of MongoDB records or a table of MySQL rows. Similarly, an entity represents a single MongoDB record, or a single MySQL row. Find methods would now exist on the `Table` class, while `Entity` classes might have methods relating to data access.

A short example:

```php
<?php
public function view($id = null) {
  $this->error404Unless($id);

  $user_id = $this->Auth->user('id');

  $post = $this->Post->findById($id)->first();
  $this->error404Unless($post && $post->isViewableByUser($user_id));

  $post->incrementViewCount();
  $this->set(compact('post'));
}
?>
```

In the above example, our normal `Post` model class is now a `Table` class. We call a find method on it and return a `$post` Entity object. This `$post` entity has two user-defined methods, `isViewableByUser` and `incrementViewCount`, which we can only call on a single `entity`.

The obvious benefit of this is that we don't need to jam all our data-related methods into a single class. That is *excellent*.

So how the hell do we do this in our 2.0 applications?

## CakeEntity

> This plugin *should* work, though the api will not exactly correspond to 3.0. Pull requests accepted, but keep this in mind!

In 2.0 - and 1.3 to an extent - there is the wonderful `CakeEntity` plugin. It was originally developed by the wonderful folks at [Kanshin](https://www.facebook.com/kanshinkukan), though I have started maintaining a [2.0 branch here](https://github.com/josegonzalez/cakephp-entity).

Installation is quite easy. Add the following to your `composer.json`:

```javascript
"josegonzalez/cakephp-entity": "1.0.0"
```

And then run the `composer update` command to install the dependency. If you do not have `CakePlugin::loadAll();` in your `bootstrap.php`, you'll want to add the following:

```php
<?php
CakePlugin::load('Entity');
?>
```

Any time you `extend AppMode`, you'll need to `extend EntityModel` instead, like so:

```php
<?php
App::uses('EntityModel', 'Entity.Model');

class Post extends EntityModel {

}
?>
```

Table methods stay in your `Post` model class. Entity methods will go in a new class. I tend to place mine in `app/Model/Entity/`, though you can do as you like. Here we have our `PostEntity` class in `app/Model/Entity/PostEntity.php`:

```php
<?php
App::uses('Entity', 'Model/Entity');

class PostEntity extends Entity {
    // Your custom logic here
}
?>
```

Remember to add the appropriate `App::uses` statement to the top of your `Post` model class for this entity. It will otherwise use any currently autoloaded `AppEntity` class (one exists within the plugin, but you should override it in your app):

```php
<?php
App::uses('EntityModel', 'Entity.Model');
App::uses('PostEntity', 'Model/Entity');

class Post extends EntityModel {

}
?>
```

### AppEntity

Usually I'll create my custom `AppEntity` class from which all my entities extend:

```php
<?php
App::uses('Entity', 'Entity.Model');

class AppEntity extends Entity {
}
?>
```

> For this section, let's assume all methods go in our new `AppEntity` class

In PHP 5.4, there is a new interface called `JsonSerializable`. When you call `json_encode` on an object, if it implements this interface, it will be serialized according to your specifications. Lets implement it:

```php
<?php
  public function jsonSerialize() {
    return $this->toArray();
  }
?>
```

Lets also add a helper method - `toJson` - that can retun json directly:

```php
<?php
  public function toJson($full = true) {
    $data = $this->jsonSerialize();
    if ($full == true) {
      return json_encode($data);
    }

    $model = $this->getModel();
    return json_encode($data[$this->alias]);
  }
?>
```

There is some extra logic here so that we can skip related entities or only return the data within this entity.

I'll also add a few methods to retrieve the current object's application route. This assumes all actions that would retrieve a single entity are called `view`, though we can override it:

```php
<?php
  protected $_viewAction = 'view';

  public function bind(EntityModel $model, $data) {
    parent::bind($model, $data);
    $this->_controllerName = Inflector::pluralize(Inflector::underscore($model->name));
  }

  public function url() {
    return Router::url($this->route(), true);
  }

  public function route() {
    $route = array(
      'controller' => $this->_controllerName,
      'action' => $this->_viewAction,
      $this->id
    );

    $slug = $this->url_slug();
    if ($slug !== null) {
      $route[] = $slug;
    }

    return $route;
  }

  public function url_slug() {
    $model = $this->getModel();
    if ($model->primaryKey == $model->displayField) {
      return null;
    }

    return Inflector::slug(strtolower($this->{$model->displayField}), '-');
  }
?>
```

As a bonus, we also add *pretty* SEO urls for each route :)

I also personally like adding a magic-method that allows me to retrieve any property as it's sanitized version. For instance, `$post->text` vs `$post->text()`. The latter can be output on the page, whereas the former is what's stored in the database. In 3.0, all data is retrieved by `$post->get('text')`, so this implementation would be a bit different. Keep that in mind.

> The Sanitize class will be removed in 3.0, so I would recommend finding an alternative before then if you use the following methodology:

```php
<?php
  public function __call($function, $args) {
    if (!empty($args) || !property_exists($this, $function)) {
      throw new NotImplementedException(array($function));
    }

    if (empty($this->$function)) {
      return '';
    }

    return Sanitize::clean($this->$function);
  }
?>
```

## Entities

If I have a `PostEntity` and want to display one thing versus another if the currently logged in user owns the post, then I would have the following:

```php
<?php
App::uses('AppEntity', 'Model/Entity');

class PostEntity extends AppEntity {
  public function isOwnedBy($user_id) {
    return $user_id == $this->user_id;
  }
}
?>
```

And the above would be called via `$post->isOwnedBy($some_id)`.

Note that you would also be able to continue using array methods through the magic of `ArrayAccess`:

```php
<?php
$post_titles = array_map(function ($post) {
  return Set::extract($post, 'Post.title');
}, $posts);
?>
```

I'd also place special routing methods in entity classes:

```php
<?php
  public function routeForLoggedInUsers() {
    // custom logic here
  }
?>
```

### Table Classes

Place anything that acts upon a `collection` of entities here:

```php
<?php
class Post extends EntityModel {
  public function _findLatest($state, $query, $results = array()) {
    // logic here
  }
}
?>
```

And I would also place anything that might create an entity and save it in one shot:

```php
<?php
  function approvePost($post_id, $approve_user_id) {
    $post = $this->find('first', array(
      'conditions' => array('Post.id' => $post_id),
      'entity' => true,
    ));
    $post = $this->findById($post_id);
    $post->approve($approve_user_id);
    return $post->save();
  }
?>
```

## Onwards to 3.0

The above is obviously a taste of what is to come in 3.0. While the api might change, the ideas are still the same, so be aware of the types of changes you'll have to make to adjust to this post-entity-world.
