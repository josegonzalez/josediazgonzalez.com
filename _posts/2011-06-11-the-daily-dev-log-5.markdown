---
  title: The Daily Dev Log - 5
  category: Dev Log
  tags:
  description: Writing a CakeRoute might be straightforward, and when used correctly, can really trim down the number of routes you connect in your routes.php file.
  comments:    true
  sharing:     true
  published:   true
  layout:      post
---

Last night, someone came into the `#cakephp` irc room on freenode,  attempting to place static html files in the `app/webroot` directory. I was able to steer him towards the solution of moving them to the `app/views/pages` directory, but then he had the following question:

{% blockquote philboy2011 %}
is it possible to remove the pages/ on the url?
{% endblockquote %}

The hard way is to specify each in your `app/config/routes.php` one as follows:

```php
Router::connect('/about', array(
    'controller' => 'pages',
    'action' => 'display'
    'about'
));
Router::connect('/legal', array(
    'controller' => 'pages',
    'action' => 'display'
    'legal'
));
Router::connect('/policy', array(
    'controller' => 'pages',
    'action' => 'display'
    'policy'
));
```

This is incredibly inefficient for several reasons. One, we have to add another route each and every time we add a new page. Or remove it once the page has been deleted. Two, it both clutters up the `app/config/routes.php` file, as well as uses increasingly more and more memory each time we add a new route. This can be mitigated by using the following technique (from [teknoid's post](http://nuts-and-bolts-of-cakephp.com/2011/03/15/dealing-with-static-pages-v2-or-3/)):

```php
$staticPages = array(
    'about',
    'legal',
    'policy',
);

$staticList = implode('|', $staticPages);

Router::connect('/:static', array(
    'controller' => 'pages',
    'action' => 'display'), array(
            'static' => $staticList,
            'pass' => array('static')
        )
    );
?>
```

So now we only have one extra route, but we also have to ensure that we update the `$staticPages` variable each time we add a new page. I'm too lazy for that.

Fortunately someone came up with a brilliant idea around this. Geoffrey Gabbers has a [blog post](http://garbers.co.za/2011/06/01/static-pages-in-cakephp/) that utilizes some fancy `glob()` footwork to figure out if that page should be routed:

```php
$availablePages = glob(VIEWS . 'pages' . DS . '*.ctp');
if ($availablePages) {
    $extensions = array_pad(array(), count($availablePages), '.ctp');
    $availablePages = array_map('basename', $availablePages, $extensions);
    Router::connect('/:page',
        array('controller' => 'pages', 'action' => 'display'),
        array('page' => implode('|', $availablePages), 'pass' => array('page'))
    );
}
```

{% pullquote %}
CakeRoute classes are available as of 1.3, and will be available in the upcoming 2.0 release
{% endpullquote %}

Cool, but now my routes look fugly as sin. Which is the opposite of I want. So with the help of CakePHP 1.3, I came up with a solution using `CakeRoutes`.

`CakeRoute` classes are small classes that extend the router in some non-trivial way. [Mark Story introduced them](http://mark-story.com/posts/view/using-custom-route-classes-in-cakephp) in a blog post about a year and a half ago, and I haven't seen too much done with them. The basic premise is that with a CakeRoute, it is possible to extend the Regex magic and Reverse Routing in order to match urls to a specific route that would otherwise be impossible. For example, Miles Johnson has a [RedirecRoute](https://github.com/milesj/cake-redirect_route) class that handles routing legacy routing to new urls in a clean way.

I figured I'd take a stab at my issue by writing a small routing class. A can of soda and a few minutes later, I had a working implementation of [PageRoute](https://github.com/josegonzalez/page_route).

CakeRoute classes need only define the `match()` and `parse()` methods. In my case, to make it even more automagic, I override the PHP4-style constructor - which seems to be called over the PHP5-style constructor even though `CakeRoute` the classes do not extend the CakePHP `Object` class - to provide some consistent defaults. Now setting up new `/:page` style routes is as simple as adding the following to your `app/config/routes.php` file:

```php
App::import('Lib', 'PageRoute.PageRoute');
Router::connect('/:page', array('controller' => 'pages', 'action' => 'display'),
    array('routeClass' => 'PageRoute')
);
```

Thats all that is needed. No need for any further configuration, although my [plugin](https://github.com/josegonzalez/page_route) does allow it if necessary. Feel free to catch it on Github :)
