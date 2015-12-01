---
  title:       "Writing Slimmer Controllers"
  date:        2013-12-24 13:27
  description: "Refactoring Controller code should be simple, and I'll tear apart my own code to show how you can go about it."
  category:    cakephp
  tags:
    - cakeadvent-2013
    - cakephp
    - controllers
  comments:    true
  sharing:     true
  published:   true
  layout:      post
  series:      CakeAdvent-2013
  image:       "http://cl.ly/image/1N0c441i1M3Y/Screen%20Shot%202013-12-24%20at%202.17.53%20PM.png"
  image_url:   "http://cl.ly/image/1N0c441i1M3Y"
  image_tooltip: "Wow, such code, so slim, many refactor"
---

> Note: I am using the CakeEntity plugin [from a previous post](/2013/12/05/objectifying-cakephp-2-0-applications/) in this example. Feel free to ignore that code if it helps simplify what is going on.

I want to take a little time and go over ways in which we can slim down model code. Below is some early code from an application I developed - it handles lunch scheduling for small companies and teams.

```php
<?php
public function add($restaurant_id = null) {
  if (empty($restaurant_id)) {
    return $this->redirect(array('action' => 'index'));
  }

  $lunchDate = $this->Lunch->find('first', array(
    'entity' => true,
    'conditions' => array('Lunch.date' => date('Y-m-d')),
    'contain' => array('Restaurant'),
  ));

  if (!empty($lunchDate)) {
    return $this->redirect(array('action' => 'update', $restaurant_id));
  }

  $this->_breadcrumbs[] = array(
    'name', => 'Create Lunch Date',
    'url' => array(),
  );

  $this->set(compact('restaurant_id'));

  if (!empty($this->request->data['cancel'])) {
    $this->Session->info('Lunch canceled');
    return $this->redirect(array('action' => 'index'));
  }

  if (!$this->request->is('post')) {
    $data = $this->Lunch->getData('add');
    return $this->set($data);
  }

  try {
    $entity = $this->Lunch->addEntity($this->request->data);
    $this->Session->success(__('The Lunch has been saved.'));
    return $this->redirect($entity->route());
  } catch (Exception $e) {
    $this->Session->danger($e->getMessage());
    if ($entity) {
      $this->request->data = $entity->toArray();
    }

    $data = $this->Lunch->getData('add');
    return $this->set($data);
  }
}
?>
```

The above is about 50 lines of code that essentially handles:

- Finding an associated lunchdate
- Form cancelation
- Breadcrumbs for the view
- Creating a lunchdate

This could and should be way smaller, and more reusable. Lets take a look at this in chunks.

## Requiring action arguments

```php
<?php
if (empty($restaurant_id)) {
  return $this->redirect(array('action' => 'index'));
}
?>
```

Some people will have issues with how I do this, but because I use [exceptions to handle redirection](/2013/12/12/abusing-exceptions-to-provide-model-layer-redirection/), this method works out well for me. I normally have a helper method in my AppController, `AppController::redirectUnless()`, with the following contents:

```php
<?php
public function redirectUnless($variable, $redirectTo = null) {
  if (!empty($variable)) {
    return;
  }

  if (empty($redirectTo)) {
    $redirectTo = array('action' => 'index');
  }

  return $this->redirect($redirectTo);
}
?>
```

Then my code sample becomes:

```php
<?php
$this->redirectUnless($restaurant_id);
?>
```

> If your tests excepted a return, this won't work because PHP does not have conditional returns without guard statements.

## Custom finds:

```php
<?php
$lunchDate = $this->Lunch->find('first', array(
  'entity' => true,
  'conditions' => array('Lunch.date' => date('Y-m-d')),
  'contain' => array('Restaurant'),
));

if (!empty($lunchDate)) {
  return $this->redirect(array('action' => 'update', $restaurant_id));
}
?>
```

I absolutely hate writing finds in my view. Instead, I use custom finds:

```php
<?php
App::uses('EntityModel', 'Entity.Model');
App::uses('LunchEntity', 'Model/Entity');
class Lunch extends EntityModel {
  public $findMethods = array(
    'lunchDate' => true,
  );

  public function _findLunchDate($state, $query, $results = array()) {
    if ($state == 'before') {
      $query['entity'] = true;
      $query['conditions'] = array('Lunch.date' => date('Y-m-d'));
      $query['contain'] = array('Restaurant');
      $query['limit'] = 1;
      return $query;
    }

    if (empty($results[0])) {
      return false;
    }

    return $results[0];
  }
}
?>
```

It's quite easy to setup a custom find - they have `before` and `after` states, and can have logic that applies to both. Please [read the docs for more information](http://book.cakephp.org/2.0/en/models/retrieving-your-data.html#creating-custom-find-types).

Our code sample would finally become:

```php
<?php
$lunchDate = $this->Lunch->find('lunchDate');
$this->redirectUnless($lunchDate, array('action' => 'update', $restaurant_id));
?>
```

## Handling common view data

```php
<?php
$this->_breadcrumbs[] = array(
  'name', => 'Create Lunch Date',
  'url' => array(),
);
?>
```

I usually have some common view data, such as meta tags, breadcrumbs, etc. that are set from each controller. Rather than have the underlying datastructure be exposed to each controller - the `_breadcrumbs` array - I use a helper method:

```php
<?php
protected function _addBreadcrumb($name, $url = array()) {
  $this->_breadcrumbs[] = compact('name', 'url');
}
?>
```

Then my controller code becomes:

```php
<?php
$this->_addBreadcrumb('Create Lunch Date');
?>
```

## Handling Form Cancellation

```php
<?php
if (!empty($this->request->data['cancel'])) {
  $this->Session->info(__('Lunch canceled'));
  return $this->redirect(array('action' => 'index'));
}
?>
```

My forms commonly have some sort of *cancel* button on them. If pressed, the user will be brought back to the index action.

Instead, I use some generic code in my `AppController::beforeFilter()`:

```php
<?php
public function beforeFilter() {
  if (!empty($this->request->data['cancel'])) {
    $this->Session->info(__('%s canceled', $this->modelClass));
    return $this->redirect(array('action' => 'index'));
  }
}
?>
```

Now I do not need to worry about having this logic in any of my actions.

## Generic Form Handling

```php
<?php
if (!$this->request->is('post')) {
  $data = $this->Lunch->getData('add');
  return $this->set($data);
}

try {
  $entity = $this->Lunch->addEntity($this->request->data);
  $this->Session->success(__('The Lunch has been saved.'));
  return $this->redirect($entity->route());
} catch (Exception $e) {
  $this->Session->danger($e->getMessage());
  if ($entity) {
    $this->request->data = $entity->toArray();
  }

  $data = $this->Lunch->getData('add');
  return $this->set($data);
}
?>
```

The trick to generic form handling is doing it in such a way to allow developers to override the functionality. Note that this means *all* your forms *should* be handled similarly. If not, there is no gain from creating a generic form handling method. The following is what I used in this application:

```php
<?php
protected function _form($entity = null, $modelClass = null) {
  if (empty($modelClass)) {
    $modelClass = $this->modelClass;
  }

  $_action = $this->request->params['action'];
  if ($entity && empty($this->request->data)) {
    $this->request->data = $entity->toArray($_action);
  }

  if (!$this->request->is($entity ? 'put' : 'post')) {
    $data = $this->{$modelClass}->getData($_action);
    return $this->set($data);
  }

  try {
    $method = $entity ? 'updateEntity' : 'addEntity';
    $entity = $this->{$modelClass}->$method($this->request->data, $entity);
    $this->Session->success(__('The %s has been saved.', Inflector::humanize($modelClass)));
    return $this->redirect($entity->route());
  } catch (Exception $e) {
    $this->Session->danger($e->getMessage());
    if ($entity) {
      $this->request->data = $entity->toArray();
    }

    $data = $this->{$modelClass}->getData($_action);
    return $this->set($data);
  }
}
?>
```

The above bit of code handles:

- Existing records being passed in
- Models that are not the default model associated to the controller
- Both creation and updating records
- Session flash messages
- Updating post data on failure
- Retrieving data for the view

Using the above helper method would simplify our action code to:

```php
<?php
return $this->_form();
?>
```

## All Together

Our previous codeblock of 49 lines is now the following, beautiful 10 line method:

```php
<?php
public function add($restaurant_id = null) {
  $this->redirectUnless($restaurant_id);

  $lunchDate = $this->Lunch->find('lunchDate');
  $this->redirectUnless($lunchDate, array('action' => 'update', $restaurant_id));

  $this->_addBreadcrumb('Create Lunch Date');
  $this->set(compact('restaurant_id'));
  return $this->_form();
}
?>
```

What we gain from the new code:

- Simpler design
- Easier to understand for new developers
- Unit tests for the parts can be created as opposed for the whole
- Reusable methods have been created for other places across the codebase

Refactoring code is easy to get carried away with - as we did above - but also serves to freshen up a codebase and allow you to get more stuff done in less time.
