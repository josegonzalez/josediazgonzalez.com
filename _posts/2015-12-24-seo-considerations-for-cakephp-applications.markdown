---
  title:       "SEO Considerations for CakePHP Applications"
  date:        2015-12-24 12:00
  description: "Silly hacks you can use in your cakephp applications"
  category:    cakephp
  tags:
    - cakeadvent-2015
    - cakephp
    - seo
    - routing
    - behaviors
    - annotations
  comments:    true
  sharing:     true
  published:   true
  layout:      post
  series:      CakeAdvent-2015
---

> A lovely post that is an adventure across how you can bend CakePHP to your will.

Everyone loves free traffic, right? It allows us to continue building our applications, hopefully making money as we do so. If you aren't making money, then why are you working on that app?

In any case, one thing that you should worry about is duplicate website content. If search engines see any such duplicate content - especially en masse - then the value of your web pages decreases in their eyes, potentially dropping your page views. That would be sucks.

One way to do this would be to automatically check that a url for a given page is the same as that which we expect. We can do this in a few ways, but the simplest is simply to check it manually!

```php
/**
 * @param integer $id an id for the current model
 * @return void|Cake\Network\Request
 */
public function view($id)
{
  $post = $this->Posts->get($id);
  if ($this->request->here != $post->getCanonicalUrl()) {
    return $this->redirect($post->getCanonicalUrl());
  }
  $this->set('post', $post);
}
```

Not too bad. One thing I like to do is use annotations for stuff, so I wrote an annotation parser for just the above:

```php
public function initialize()
{
  $this->loadComponent('SeoAnnotation', [
    // this can be overriden
    'table' => 'Posts',
    // as can this
    'primaryKey' => '$id',
  ]);
}

/**
 * @table Posts
 * @param integer $id an id for the current model
 * @return void|Cake\Network\Request
 */
public function view($id)
{
  $post = $this->Posts->get($id);
  $this->set('post', $post);
}
```

The annotation parser - using the [minime/annotations](https://github.com/marcioAlmada/annotations) package - simply retrieves the entity on the specified table by the specified field and then automatically does the following:

```php
protected function getTable()
{
  $annotations = $this->geAnnotations();
  $tableClass = $annotations->get('table', $this->config('table'));
  return TableRegistry::get($tableClass);
}

protected function getPrimaryKey()
{
  $annotations = $this->geAnnotations();
  $primaryKeyField = $annotations->get(
    'primaryKey',
    $this->config('primaryKey')
  );
  // logic to iterate over other @param
  // annotations to get the index of the primaryKey
  // in the current request args
  return $primaryKey;
}

protected function beforeFilter(\Cake\Event\Event $event)
{
  $primaryKey = $this->getPrimaryKey();
  if (empty($primaryKey)) {
    return;
  }

  $entity = $this->getTable()->get($primaryKey);
  if (!method_exists($entity, 'getCanonicalUrl')) {
    throw new \RuntimeException('Your entity class must implement getCanonicalUrl');
  }

  if ($this->request->here != $entity->getCanonicalUrl()) {
    return $this->redirect($entity->getCanonicalUrl());
  }
}
```

Of course, if the specified field doesn't exist as an `@param` docblock, then my component does nothing. It does require a bit more work on the developer's end, but as a bonus I also get well-documented code.

Note, you can always get at a controller in your custom components by doing the following:

```php
$controller = $this->_registry->getController();
```

Components are "owned" by a `Cake\Controller\ComponentRegistry`, which keeps track of both loaded components and the controller upon which they are loaded, amongst other things.

> Semi-related, ComponentRegistry, TableRegistry, etc. are all simply [service locators](http://en.wikipedia.org/wiki/Service_locator_pattern), and all use some form of dependency injection on the objects they build. Yes, CakePHP has those things you thought it didn't, we're just very good at hiding them from you :P
> If you'd like to use a similar pattern in your applications, you can extend the `Cake\Core\ObjectRegistry` class. I personally use this for stuff like custom payment classes, or things where there are multiple implementations and constructing them can be a pita.

Back on topic, once I have an entity, I also like to set the canonical url for a given page. For instance, sometimes my page has querystring values that I'd like search engines to ignore. Maybe they were affiliate parameters, or things that updated filters. In any case, it's a good idea to set a `rel=canonical` meta tag:

```php
if (method_exists($entity, 'getCanonicalUrl') {
  $this->_controller->set('metaCanonical', $entity->getCanonicalUrl());
}
```

And then in your view:

```php
// there isn't a special helper for this,
// so we are just using HtmlHelper::tag()
echo $this->Html->tag('link', null, [
  'rel' => 'canonical',
  // get the full url, since we don't expect `getCanonicalUrl`
  // to return with the domain etc.
  'href' => \Cake\Routing\Router::url($metaCanonical, true),
]);
```

When writing an application, we often want memorable names. `/posts/view/34523` is a boring url, but `/2015/12/24/seo-considerations-for-cakephp-applications/` tells me a bit more. But how do I do routing off of that?

One thing that is useful to to *still* have the "primarykey" to a record in the url. For instance, you might have the following url:

```
/34523/seo-considerations-for-cakephp-applications/
```

That still has an ID I can look for, and also contains some interesting metadata for both the user and a search engine. But how do we generate that slug? Using plugin LIKE A BAWS:

```php
# install the thing!
composer require muffin/slug

# enable the thing!
bin/cake plugin load Muffin/Slug
```

And now add the behavior to your table:

```php
<?php
namespace App\Model\Table;

use Cake\ORM\Table;

class PostsTable extends Table
{
  public function initialize(array $config)
  {
    // some other crap you think is code goes here
    $this->displayField('title');
    $this->addBehavior('Muffin/Slug.Slug', [
      // options! https://github.com/UseMuffin/Slug#configuration
    ]);
  }
}
?>
```

And now, as long as you have a `slug` field in your `posts` table and a `title` field as your displayField, you will be set. You can now use the `slug` in your `getCanonicalUrl` method.

But why stop there? You could also build a simple admin tool to let your marketing team update those canonical urls using the [crud](/2015/12/02/creating-apis-using-the-crud-plugin/) and [crud-view](/2015/12/03/generating-administrative-panels-with-crud-view/) plugin. Trust me, they'll love you and sing your praises to your bosses, which will be especially nice when you realize you are programming on Christmas day and your boss is like "slow your roll, you did great work this year, go take a nice long vacation and come back to me fresh next year."

And that's all I have. Come back next year - or whenever I decide to write again - and we'll see if I can muster up more tips and tricks you can use in writing your CakePHP code. Until then, pet your pets and Happy Holidays!
