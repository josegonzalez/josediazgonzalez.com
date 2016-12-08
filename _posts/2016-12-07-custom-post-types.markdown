---
  title:       "Custom Post Types"
  date:        2016-12-07 06:04
  description: "Part 7 of a series of posts that will help you build out a personal CMS"
  category:    cakephp
  tags:
    - events
    - forms
    - cakeadvent-2016
    - cakephp
  comments:    true
  sharing:     true
  published:   true
  layout:      post
  disable_advertisement: true
  series:      CakeAdvent-2016
---

A friend of mine asked for a custom website, so here I am, writing a custom cms. I know, there are plenty of systems out there that would handle his needs, but it's also a good excuse to play around with CakePHP 3, so here we are.

> For the lazy, the codebase we'll be working on will be available on [GitHub](https://github.com/josegonzalez/cakeadvent-2016). I will be pushing each set of changes on the date when each blog post in this series is published. No cheating!

## Custom Post Types

For our cms, the following post types are things my client wants to have on their site:

- General Blog Posts
- Photos
- Photos with text attached
- Photos with an optional price tag - for purchasing

A bit across the board, but lets see if we can make this a bit generic:

- title
- content (optional)
- image (optional)
- price (optional)

Above is a list of fields that we'll need to provide. The `title` is required, and will be used to interpolate a url, assuming one isn't specified by the user. All others are "optional" for every type, but can be mandatory depending upon the post type. It seems that each post type would need to be able to set it's own validation rules at least. As each post type varies in it's fields, we'll also want to be able to specify a schema for use on the edit page itself.

If any of the above sounds familiar, its because I've described a `Form` class. Here is an example Form class for my app:

```php
<?php
BlogPostType extends Form
{
    protected function _buildSchema(Schema $schema)
    {
        $schema->addField('title', 'string');
        $schema->addField('url', ['type' => 'text']);
        $schema->addField('body', ['type' => 'text']);
        return $schema
    }

    protected function _buildValidator(Validator $validator)
    {
        $validator->notEmpty('title', 'Please fill this field');
        $validator->notEmpty('url', 'Please fill this field');
        $validator->notEmpty('body', 'Please fill this field');
        return $validator;
    }

    protected function _execute(array $data)
    {
        // Logic here to save the thing.
        return true;
    }
}
```

Pretty neat. One thing is that the optional fields cannot be saved into the `posts` table, as there is no place for them there. Our `_execute` method will need to turn them into `PostAttributes` for the purposes of using it in the ui. As well, we'll need a method for turning the `PostAttributes` data into something our form template will be able to understand. As such, extracting that logic into a new class seems reasonable. Here is the skeleton for that:

```php
<?php
namespace App\PostType;

use Cake\ORM\TableRegistry;
use Cake\Utility\Inflector;

abstract class AbstractPostType extends Form
{
}
```

First, lets get the generic `AbstractPostType::_execute()` method out of the way. This method needs to massage the data into a `Post` entity and it's related `PostAttributes` entities.

```php
protected function _execute(array $data)
{
    $postsTable = TableRegistry::get('Posts');
    $attributesTable = TableRegistry::get('PostAttributes');
    $postAttributes = [];

    $postFields = ['id', 'user_id', 'title', 'url'];
    foreach ($data as $key => $value)
    {
        if (in_array($key, $postFields)) {
            continue;
        }
        $postAttributes[] = $attributesTable->newEntity([
            'name' => $key,
            'value' => $value,
        ]);
        unset($data[$key]);
    }

    $post = $postsTable->newEntity($data);
    $post->post_attributes = $postAttributes;
    return $postsTable->save($post);
}
```

We also need to make a method that returns an array of data based on an incoming `Post` entity and it's related `PostAttribute` entities.

```php
public function data(Post $post)
{
    $data = $post->toArray();
    unset($data['post_attributes']);
    foreach ($post->post_attributes as $postAttribute) {
        $data[$postAttribute->name] = $postAttribute->value;
    }
    return $data;
}
```

For templating purposes, I will also create a `get` method that can be used to get an individual attribute.

```php
public function get($key, $default = null)
{
    if (empty($this->_data)) {
        $this->_data = $this->data();
    }

    if (isset($this->_data[$key])) {
        return $this->_data[$key];
    }
    return $default;
}
```

And finally, a few methods for deciding what template to use for `index` and `view` actions.

```php
public function indexTemplate()
{
    return $this->templatePrefix() . '-index.ctp'
}

public function viewTemplate()
{
    return $this->templatePrefix() . '-view.ctp'
}

protected function templatePrefix()
{
    $template = get_class($this);
    if ($pos = strrpos($template, '\\')) {
        return substr($template, $pos + 1);
    }

    $template = preg_replace('/PostType$/', '', $template);
    return 'post_type/' . Inflector::underscore($template);
}
```

> You'll want to change the class that `BlogPostType` extends to `App\PostType\AbstractPostType`.

## Distributing Post Types

One thing that would be cool is if I could add a new post type without adding code to the main app. This would allow me to decouple building post types, and potentially make them shareable across CMS installations. This requirement would mean that we should lean on plugins. Here is a theoretical `BlogPostTypePlugin`:

```
plugins/BlogPostTypePlugin/config/bootstrap.php
plugins/BlogPostTypePlugin/src/PostType/BlogPostType.php
plugins/BlogPostTypePlugin/src/Template/Element/post_type/blog-index.ctp
plugins/BlogPostTypePlugin/src/Template/Element/post_type/blog-view.ctp
```

> It would also be cute if we could inject css/js into our cms, but I think that might be pushing it. For now we should instead rely on the cms theme or whatever to set what that looks like.

Other than our `BlogPostTypePlugin` class - which extends the core `PostType` - we will need to use `config/bootstrap.php` to register post types. We can do so via the event system. Here is what that might look like:

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

We'll need an element to render the post type on the screen.

Our view template might look like the following:

```php
<h3><?= $post->get('title') ?></h3>
<div>
  <?= $post->get('body') ?>
</div>
```

The above setup should allow us to create custom plugins that contain one or post types. While the parsing bit isn't shown here, it's simply a matter of dispatching the event and then collecting the `postTypes` attribute on the subject.

Lets add the `PostType` class:

```shell
git add src/PostType/AbstractPostType.php
git commit -m "Lay out infrastructure for custom post types"
```

---

> For those that may just want to ensure their codebase matches what has been done so far, the codebase is available on GitHub and tagged as [0.0.8](https://github.com/josegonzalez/cakeadvent-2016/tree/0.0.7).

We now have an - unproven - post type system. We still have yet to have a way to display this on the site, nor have we started on what it looks like to edit the page, but we'll get there. I'm pretty happy with what we have so far, and hopefully we can figure out any specific issues as we start using this system.

Be sure to follow along via twitter on [@savant](https://twitter.com/savant). If you'd like to subscribe to this blog, you may follow the [rss feed here](/atom.xml). Also, all posts in the series will be conveniently linked on the sidebar of every post in the 2016 CakeAdvent Calendar. Come back tomorrow for more delicious content.
