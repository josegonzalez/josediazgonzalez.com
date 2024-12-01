---
category: cakephp
comments: true
date: 2016-12-08 08:04
description: Part 8 of a series of posts that will help you build out a personal CMS
disable_advertisement: true
layout: post
published: true
series: CakeAdvent-2016
sharing: true
tags:
- events
- forms
- plugins
- cakeadvent-2016
- cakephp
title: Displaying Custom Post Type Forms
---

A friend of mine asked for a custom website, so here I am, writing a custom cms. I know, there are plenty of systems out there that would handle his needs, but it's also a good excuse to play around with CakePHP 3, so here we are.

> For the lazy, the codebase we'll be working on will be available on [GitHub](https://github.com/josegonzalez/cakeadvent-2016). I will be pushing each set of changes on the date when each blog post in this series is published. No cheating!

## Baking a Plugin

Last post, we described what a blog post plugin would look like. Let's actually build it now. We'll start by using `bake` to generate the skeleton, which should also update our `composer.json` to update code load paths.

```shell
bin/cake bake plugin BlogPostType -f
```

Next, we'll create a `plugins/BlogPostType/config/bootstrap.php` to load our plugin post type.

```php
<?php
use Cake\Event\Event;
use Cake\Event\EventManager;

EventManager::instance()->on('Posts.PostTypes.get', function (Event $event) {
  // The key is the Plugin name and the class
  // The value is what you want to display in the ui
  $event->subject->postTypes['BlogPostType.BlogPostType'] = 'blog';
});
```

> You can remove the `plugins/BlogPostType/config/routes.php` file as we wont need it

We'll want to ensure that the bootstrap file is loaded for this plugin, so check to ensure that your `config/bootstrap.php` has the following `Plugin::load` line:

```php
Plugin::load('BlogPostType', ['bootstrap' => true, 'routes' => false]);
```

We will now need the `PostType` class that contains the code for our form. Here are the contents of `plugins/BlogPostType/PostType/BlogPostType.php`:

```php
<?php
namespace BlogPostType\PostType;

use App\PostType\AbstractPostType;
use Cake\Form\Schema;
use Cake\Validation\Validator;

class BlogPostType extends AbstractPostType
{
    protected function _buildSchema(Schema $schema)
    {
        $schema = parent::_buildSchema($schema);
        $schema->addField('body', ['type' => 'text']);
        return $schema
    }

    protected function _buildValidator(Validator $validator)
    {
        $validator = parent::_buildValidator($validator);
        $validator->notEmpty('body', 'Please fill this field');
        return $validator;
    }
}
```

Reflecting upon what I'll need to show on the view, I think I'll want to make sure we always have *some* defaults for the schema and validator, particularly around common fields. As well, I will need a way to extract viewVars that should be set by the post type for the view - for things like dropdown selects, for instance. I'll take care of that now by adding the following methods to my `AbstractPostType` class:

```php
protected function _buildSchema(Schema $schema)
{
    $schema->addField('user_id', ['type' => 'hidden']);
    $schema->addField('title', ['type' => 'string']);
    $schema->addField('url', ['type' => 'string']);
    $schema->addField('status', ['type' => 'select']);
    return $schema
}

protected function _buildValidator(Validator $validator)
{
    $validator->notEmpty('user_id', 'Please fill this field');
    $validator->notEmpty('title', 'Please fill this field');
    $validator->notEmpty('url', 'Please fill this field');
    $validator->add('status', 'inList', [
        'rule' => ['inList', ['active', 'inactive']],
        'message' => 'Status must be either active or inactive'
    ]);
    return $validator;
}

public function viewVars()
{
    $statuses = ['active' => 'active', 'inactive' => 'inactive'];
    return compact('statuses');
}
```

I noticed that we're hard-coding the whitelisted fields in `AbstractPostType::_execute()`, and that this whitelist is missing a few things. I've changed it to the following (which isn't tested but should work):

```php
$postFields = $postsTable->schema()->columns();
```

Getting back to our blog plugin, we'll need two templates for displaying on the page. I'm actually going to use the same thing for both.

```php
<h3><?= $post->get('title') ?></h3>
<div>
    <?= $post->get('body') ?>
</div>
```

We've made a bit of progress, so lets save it :)

```shell
git add composer.json config/bootstrap.php plugins/ src/PostType/AbstractPostType.php
git commit -m "New BlogPostType"
```

## Displaying the form

First, lets create a method of retrieving all PostTypes. I made the following trait at `src/Traits/PostTypesTrait.php` to contain this logic:

```php
<?php
namespace App\Traits;

use Cake\Event\Event;
use Cake\Event\EventManager;
use Crud\Event\Subject;

trait PostTypesTrait
{
    static $postTypes = null;

    public static function postTypes()
    {
        if (static::$postTypes !== null) {
            return static::$postTypes;
        }

        $event = new Event('Posts.PostTypes.get');
        $event->subject = new Subject([
            'postTypes' => [],
        ]);

        EventManager::instance()->dispatch($event);
        if (!empty($event->subject->postTypes)) {
            static::$postTypes = $event->subject->postTypes;
        } else {
            static::$postTypes = [];
        }
        return static::$postTypes;
    }
}
```

Next, add this trait to the PostsListener class:

```php
use App\Traits\PostTypesTrait;
```

We'll need to add a `beforeRender` event handler to our `PostsListener` so we can properly populate the form. Start by adding the handler to our `PostsListener::implementedEvents()`:

```php
'Crud.beforeRender' => 'beforeRender',
```

The handler should:

- get the post type from the url - mapping `/posts/add/blog` to our `BlogPostType`
- load the correct class
- set any view variables
- ensure the schema is specified correctly

Here is the logic for that method (and others):

```php
/**
 * Before Render
 *
 * @param \Cake\Event\Event $event Event
 * @return void
 */
public function beforeRender(Event $event)
{
    if ($this->_controller()->request->action === 'add') {
        $this->beforeRenderAdd($event);

        return;
    }
}

/**
 * Before Render Add Action
 *
 * @param \Cake\Event\Event $event Event
 * @return void
 */
public function beforeRenderAdd(Event $event)
{
    $postTypes = PostsListener::postTypes();
    $request = $this->_request();
    $passedArgs = $request->param('pass');

    $postType = null;
    if (!empty($passedArgs)) {
        $type = $passedArgs[0];
        foreach ($postTypes as $class => $alias) {
            if ($alias === $type) {
                $postType = $class;
            }
        }
    }

    if ($postType !== null) {
        $className = App::className($postType, 'PostType');
        $postType = new $className;
        $fields = [];
        foreach ($postType->schema()->fields() as $field) {
            $fields[$field] = [
                'type' => $postType->schema()->fieldType($field)
            ];
        }

        $viewVars = $postType->viewVars();
        $viewVars['fields'] = $fields;
        $this->_controller()->set($viewVars);
        $event->subject->set(['entity' => $postType]);
    }
}
```

Woot! If you go to `/posts/add/blog`, you'll see that our form is properly rendered by the CrudView. Neat!

```shell
git add src/Listener/PostsListener.php src/Traits/PostTypesTrait.php
git commit -m "Properly display the post type form"
```

---

> For those that may just want to ensure their codebase matches what has been done so far, the codebase is available on GitHub and tagged as [0.0.8](https://github.com/josegonzalez/cakeadvent-2016/tree/0.0.8).

It may not seem like much, but we've laid the groundwork for actually using custom post types. In our next segment, we'll look at how to actually save the above data, persisting data for editing, and a ui for selecting the post type to add.

Be sure to follow along via twitter on [@savant](https://twitter.com/savant). If you'd like to subscribe to this blog, you may follow the [rss feed here](/atom.xml). Also, all posts in the series will be conveniently linked on the sidebar of every post in the 2016 CakeAdvent Calendar. Come back tomorrow for more delicious content.
