---
  title:       "Using Fractal to transform entities for custom api endpoints"
  date:        2015-12-01 13:42
  description: "Silly hacks you can use in your cakephp applications"
  category:    cakephp
  tags:
    - cakeadvent-2015
    - cakephp
    - api
    - entities
  comments:    true
  sharing:     true
  published:   true
  layout:      post
  series:      CakeAdvent-2015
---

In a CakePHP 3 application, you can very easily create Apis with entity objects. Each entity implements the `JsonSerializable` interface, and you can customize the output by creating a custom `toArray()` method (or `jsonSerialize()` if you want to skip a step):

```php
<?php
namespace App\Model\Entity;
use Cake\ORM\Entity;
use Cake\Routing\Router;

class Post extends Entity
{
    public function toArray()
    {
        // Special logic goes here
        $data = parent::toArray();
        return $data;
    }
}
?>
```

If you serialized a set of these entities, you would have something like:

```json
{
  [{
    "id": 6,
    "title": "Herp derpes",
    "year": null
  }]
}
```

Not great, especially if this serialization changes from endpoint to endpoint.

A few months ago, it was requested that there be a way to define endpoint-specific entity serialization, which is difficult with the above type of setup. There are a few methods to go about such a thing, one of which is to use a custom View class that will automatically wrap entities.

## Fractal

Fractal is a php package by The PHP League whose description is as follows:

> Fractal provides a presentation and transformation layer for complex data output, the like found in RESTful APIs, and works really well with JSON. Think of this as a view layer for your JSON/YAML/etc.

Isn't that nice? Using fractal, we can write wrappers around arbitrary inputs and have arbitrary outputs. Fractal supports quite a few types of [transformations](http://fractal.thephpleague.com/transformers/) and [serializers](http://fractal.thephpleague.com/serializers/), so be sure to check them out.

Note that we *could* have created our own data-wrapping library, but why bother? We can and should use pre-existing libraries wherever possible for several reasons:

- The code is (hopefully) better tested
- It may provide additional features you have not yet thought of
- More mindshare can sometimes mean easier onboarding of developers

Similar to how we shouldn't re-invent a framework for work purposes, we should also strive for code re-use wherever it is feasible. In our case, The PHP League provides [quite a few delicious libraries](https://thephpleague.com/) (in some cases similar to those provided by CakePHP itself!) we can sprinkle around our CakePHP application.

## FractalEntities

Rather than have to build such integrations over and over, I built a single-purpose plugin for this case. As the use-case was very simple, it doesn't have many options - nor docs for that matter - but this post should serve as a good example of how to use it going forward.

In our case, we're going to use a wrapper plugin called FractalEntities to create a nicer-version of the json output that looks something like this:

```json
{
  "data": [{
    "id": 6,
    "title": "Herp derpes",
    "year": null,
    "links": [{
      "rel": "self",
      "uri": "\/blog\/post-1"
    }]
  }]
}
```

First, lets start out by installing the plugin using composer:

```php
composer require josegonzalez/cakephp-fractal-entities
```

This will install our wrapper `TransformerView` class which does the heavy lifting.

The simplest setup will be to set the current `Controller::$viewClass` to the `TransformerView` and set your data for serialization:

```php
$this->viewClass = 'FractalEntities.Transformer';
$this->set('_serialize', 'posts');
```

Next, we will define a transformer class. The namespace of each transformer class is interpolated based upon the current request path like so:

```php
# if you are missing any param, assume you don't
# need that section in the class namespace
$path = array_filter([
    'App',
    'Transformer',
    $this->request->param('plugin'),
    $this->request->param('prefix'),
    $this->request->param('controller'),
    $this->request->param('action') . 'Transformer',
], 'strlen');
```


For `/posts/view/1` - assuming no plugins or prefixes - you will need the following file:

```
src/Transformer/Posts/ViewTransformer.php
```

with the following class:

```php
<?php
namespace App\Transformer\Posts;

use App\Model\Entity\Post;
use League\Fractal\TransformerAbstract;

class IndexTransformer extends TransformerAbstract
{
    /**
     * Creates a response item for each instance
     *
     * @param Post $post post entity
     * @return array transformed post
     */
    public function transform(Post $post)
    {
        return [
            'id' => (int)$post->get('id'),
            'title' => $post->get('title'),
            'year' => $post->get('published_date'),
            'links' => [
                [
                    'rel' => 'self',
                    'uri' => '/books/' . $post->get('route'),
                ]
            ],
        ];
    }
}
?>
```

All transformers will need a `transform` method, which will take a single entity of whatever type you are turning into an api response. Note that due to our use of Fractal, we can be sure that whether we are converting a single entity or an entire resultset, the response will always be converted properly.

## Is this "best practice"?

The answer to that is "maybe". Perhaps for your application, separating the presentation layer from your entity layer will work out really well due to the myriad of ways data can be represented. This might also result in a lot of extra classes that are harder to navigate, or extra magic that may be difficult to understand later.

One nice thing about this method is that it is quite easy to separate presentation-layer unit tests from those relating to the entity itself. Because the entity is being wrapped away from where your business logic is located, it's much easier to reason about how the output itself.

Tomorrow I'll show you a powerful alternative for json api creation.
