---
  title:       "Using View Cells in your CakePHP applications"
  date:        2014-03-20 16:54
  description: "A look forward at writing CakePHP 3.x applications, as well as a throwback to Service classes"
  category:    cakephp
  tags:
    - cakephp
    - views
    - service
  comments:    true
  sharing:     true
  published:   true
  layout:      post
---

There is an [interesting ticket](https://github.com/cakephp/cakephp/issues/3052) in 3.x describing View Cells. Lets dive right in and figure out what they mean for CakePHP applications.

## What is a view cell?

View cells are like mini templates that are assigned to variables. A good use case for them would be to decorate entities of data. For example, consider the following example:

```php
<?php
class PostCell extends ViewCell {
    public $view = 'single_post';

    // I am renaming the method `render` to `run` for a specific reason...
    public function run(array $options = [])
    {
        $this->loadModel('Posts');
        $post = $this->Posts->findById($options['id']
        $this->set(compact('post'));
        return $this; // So I can chain the `run` method
    }
}
?>
```

The above class would retrieve the data necessary to render a `PostCell` using the `single_post` template file. Our template file could be as follows:

```php
<h1><?= $post->get('title') ?></h1>
<div class="post-content">
    <?= $post->get('content') ?>
</div>
```

In order to use this view cell, we might do the following in our `view.ctp`:

```php
<?= $this->cell('PostCell', array('id' => 10)) ?>
```

## Reusing cells with existing data

What if we already have the data, and just want to re-use our cell? This is similar to using an element, though it would be possible with some hackery:

```php
<?php
class PostCell extends ViewCell {
    public $view = 'single_post';

    public function run(array $options = [])
    {
        // Short-circuit the cell and return any passed data
        if (!empty($options['post'])) {
            $this->set('post', $options['post']);
            return $this; // So I can chain the `run` method
        }

        $this->loadModel('Posts');
        $post = $this->Posts->findById($options['id']
        $this->set(compact('post'));
        return $this; // So I can chain the `run` method
    }
}
?>
```

Our use case would be to show this on an `index.ctp` like the following:

```php
<? foreach ($posts as $post) : ?>
    <?= $this->cell('PostCell', compact('post')) ?>
<? endforeach; ?>
```

## Returning cells directly from the controller

We might also want to include the cell directly from the controller. We could do this by constructing the cell directly within the controller:

```php
<?php
class PostsController extends Controller
{
    use CellTrait;

    public function view($id)
    {
        $post = $this->Post->findById($id);
        if (!$post) {
            throw new NotFoundException('Post not found');
        }

        $this->set('post', $this->decorate('PostCell', $post));
    }
}
?>
```

And our `view.ctp` would be as follows:

```php
<?= $post ?>
```

## Retrieving Cell data from a controller

You might want to reuse *just* the cell data, and not the representation, within a controller. The following could be what the api for this looks like:

```php
<?php
class PostsController extends Controller
{
    use CellTrait;

    public function view($id)
    {
        $data = (new PostCell())->run(compact('id'))->data();
        if (empty($data['post'])) {
            throw new NotFoundException('Post not found');
        }

        // do things to $data['post']

        $this->set('post', $this->decorate('PostCell', $data['post']));
    }
}
?>
```

If the above looks familiar, it is because a PostCell can be pretty analagous to a service class, which I [previously blogged about](/2013/12/06/building-service-classes/) during CakeAdvent.

### Containing state within your service class

In the vein of reusing cells for service classes, what if we want to contain the success and failure state of the cell? We might extend our base `ViewCell` class:

```php
<?php
class AppViewCell extends ViewCell
{
    public static function perform(array $options = [])
    {
        $klass = get_called_class();
        $cell = new $klass;
        $klass->run($options);
        return $klass;
    }
}
?>
```

If you change the parent class of `PostCell` to `AppViewCell`, we can now do:

```php
<?php
$cell = PostCell::perform(array('id' => 10));
?>
```

Lets make this a bit more interesting by adding `successful` and `failed` methods:

```php
<?php
class AppViewCell extends ViewCell
{
    protected $success = null;

    public static function perform(array $options = [])
    {
        $klass = get_called_class();
        $cell = new $klass;
        $klass->run($options);
        return $klass;
    }

    public function successful()
    {
        return $successful === true;
    }

    public function failed()
    {
        return $successful === false;
    }

    public function performed()
    {
        return $successful === null;
    }
}
?>
```

We can now modify our `PostCell` class to be as follows:

```php
<?php
class PostCell extends ViewCell {
    public $view = 'single_post';

    public function run(array $options = [])
    {
        // Short-circuit the cell and return any passed data
        if (!empty($options['post'])) {
            $this->set('post', $options['post']);
            return $this; // So I can chain the `run` method
        }

        $this->loadModel('Posts');
        $post = $this->Posts->findById($options['id']
        $this->success = !!$post;

        if ($this->success) {
            $this->set(compact('post'));
        }

        return $this; // So I can chain the `run` method
    }
}
?>
```

And now our controller action could become the following:

```php
<?php
class PostsController extends Controller
{
    use CellTrait;

    public function view($id)
    {
        $cell = PostCell::perform(compact('id'));
        if ($cell->successful()) {
            $this->set('post', $this->decorate('PostCell', $cell->data()));
        }

        throw new NotFoundException('Post not found');
    }
}
?>
```

## Why use a cell?

One of the most ill-used features of CakePHP is `View::requestAction()`. Developers frequently use this all over their applications, causing convoluted cases where you need to figure out if you are within a web request or an internal action request, cluttering controllers. You also need to invoke a new CakePHP request, which can add some unneeded overhead.

You could think of View cells as lightweight request containers. Rather than constructing a new request to get at some request data, you could simply reuse cells to get at useful data without having all of the overhead involved in invoking a controller. And as I showed above, they would make excellent containers for service classes.
