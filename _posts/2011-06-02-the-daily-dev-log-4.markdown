---
  title: The Daily Dev Log - 4
  category: Dev Log
  tags:
    - daily-dev-log
  description: On the subject of updating urls in a web framework that gives you access to a router, it's important to have flexibility in writing those routes.
  comments:    true
  sharing:     true
  published:   true
  layout:      post
---

On the subject of updating urls in a web framework that gives you access to a router, it's important to have flexibility in writing those routes.

In CakePHP, the following is possible:

```php
Router::connect('/:date/:category/:id-:slug',
    array('controller' => 'posts', 'action' => 'view'),
    array('id' => '[0-9]+', 'category' => '[\w_-]+', 'slug' => '[\w_-]+', 'date' => '[0-9]{4}-[0-9]{2}-[0-9]{2}')
);
```

It's pretty easy to constrain each section as necessary using regular expressions. CakePHP also allows the usage of Router Classes that can use PHP to figure out whether a particular rule maps to a request, and how to map that request.

In Symfony, most routes are defined in a yml file:

```yaml
post_view_seo:
  url:   /:date/:category/:id/:slug/
  param: { module: posts, action: view }
  requirements: { id: "[\d]+", category: "[\w_-]+", slug: "[\w_-]+", date: "[0-9]{4}-[0-9]{2}-[0-9]{2}" }
```

You can also define routes in a php file. But it feels icky to do that and combine it with yml routing.
