---
  title:       "Routing Blog Posts to custom urls"
  date:        2016-12-17 05:21
  description: "Part 17 of a series of posts that will help you build out a personal CMS"
  category:    cakephp
  tags:
    - routing
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

## Routing built-in urls

One thing you may have noticed is that we haven't really touched our routing files. Up till now, we've relied on the default CakePHP routes to handle where our requests are sent. Because we have allowed users to specify arbitrary urls, we'll need to create custom routes to handle both our existing urls _as well as_ the custom routes we've specified for each post.

I've updated my `config/routes.php` to the following:

```php
<?php
use Cake\Core\Plugin;
use Cake\Routing\RouteBuilder;
use Cake\Routing\Router;
use Cake\Routing\Route\DashedRoute;

Router::defaultRouteClass(DashedRoute::class);

Router::scope('/', function (RouteBuilder $routes) {
    $routes->connect('/', ['controller' => 'Posts', 'action' => 'home']);
    $routes->connect('/login', ['controller' => 'Users', 'action' => 'login']);
    $routes->connect('/logout', ['controller' => 'Users', 'action' => 'logout']);
    $routes->connect('/forgot-password', ['controller' => 'Users', 'action' => 'forgot-password']);
    $routes->connect('/reset-password/*', ['controller' => 'Users', 'action' => 'forgot-password']);
});

Router::scope('/admin', function (RouteBuilder $routes) {
    $routes->scope('/posts', ['controller' => 'Posts'], function (RouteBuilder $routes) {
        $routes->connect('/', ['action' => 'index']);
        $routes->fallbacks();
    });
    $routes->connect('/profile', ['controller' => 'Users', 'action' => 'edit']);
});

Plugin::routes();
```

A few notes:

- You can specify a "default route class". This is used for inflecting urls correctly, and I'm using the CakePHP default of `DashedRoute`.
- You can specify one or more route "scopes", which are kinda like route prefixes. Routes specified within a scope have that scope prefixed onto any matching urls.
- Route scopes can have default values specified, as we do for anything in `/admin/posts`.
- Route scopes can be embedded.

Now you can use the new url patterns for any of the existing pages.

```shell
git add config/routes.php
git commit -m "Specify all hardcoded app routes"
```

## Routing Custom Urls

This part is a bit more complex. We need to do the following:

- Match a custom `/:url` catch-all pattern *only* when there is a matching url in the `posts` table.
- Allow access to `PostsController::view()`.
- Ensure the correct variables are set for the `PostsController::view()` template layer.
- Add templates for `PostsController::view()`.
- Set default views for the `PostsController::view()` action.

We'll do this piecemeal.

### Custom Route Classes

In order to match our catch-all route, we'll need a `PostRoute`. Lets first connect the route in our `config/routes.php` under the `/` scope:

```php
$routes->connect(
    '/:url',
    ['controller' => 'Posts', 'action' => 'view'],
    ['routeClass' => 'PostRoute']
);
```

Next, we'll add the following to our `PostRoute` class, located in `src/Routing/Route/PostRoute.php`.

```php
<?php
namespace App\Routing\Route;

use Cake\ORM\TableRegistry;
use Cake\Routing\Route\Route;

class PostRoute extends Route
{
    public function parse($url, $method = '')
    {
        $params = parent::parse($url, $method);
        if (empty($params)) {
            return false;
        }

        $PostsTable = TableRegistry::get('Posts');
        $post = $PostsTable->find()->where(['url' => '/' . $params['url']])->first();
        if (empty($post)) {
            return false;
        }

        $params['pass'] = [$post->id];
        return $params;
    }
}
```

This will perform a lookup for all urls that do not match another route. If the url doesn't exist in our table, we simply don't parse that request. If it does, we set the post id as the first passed argument.

Next, we need to modify our `PostsController::initialize()` method to allow access to the `PostsController::view()` action:

```php
$this->Auth->allow(['home', 'view']);
```

Now that this is set, we can use the `Crud.beforeFind` event to modify the finder to return related post data from the `post_attributes` database table. Add the following to your `PostsListener::implementedEvents()` method:

```php
'Crud.beforeFind' => 'beforeFind',
```

And here is the logic for the new `PostsListener::beforeFind()` and friends:

```php
/**
 * Before Find
 *
 * @param \Cake\Event\Event $event Event
 * @return void
 */
public function beforeFind(Event $event)
{
    if ($this->_request()->action === 'view') {
        $this->beforeFindView($event);

        return;
    }
}

/**
 * Before Find View Action
 *
 * @param \Cake\Event\Event $event Event
 * @return void
 */
public function beforeFindView(Event $event)
{
    $event->subject->query->contain(['PostAttributes']);
}
```

Pretty straightforward. I also created a `src/Template/Posts/view.ctp`:

```php
<div class="posts index large-12 medium-12 columns content">
    <?php $postType = $post->getPostType(); ?>
    <?= $this->element($postType->viewTemplate(), ['post' => $postType]); ?>
</div>
```

And one for the `DefaultTheme` plugin in `plugins/DefaultTheme/src/Template/Posts/view.ctp`:

```php
<div class="wrapper">
    <ul class="post-list">
        <li>
            <?php $postType = $post->getPostType(); ?>
            <?= $this->element($postType->viewTemplate(), ['post' => $postType]); ?>
        </li>
    </ul>
</div>
```

If you browse to the homepage of the CMS and click any of the URLs, you should now see content :)

Let's stop here for today.

```shell
git add config/routes.php plugins/DefaultTheme/src/Template/Posts/view.ctp src/Controller/PostsController.php src/Listener/PostsListener.php src/Routing/Route/PostRoute.php src/Template/Posts/view.ctp
git commit -m "Implement custom routing for blog posts"
```

---

> For those that may just want to ensure their codebase matches what has been done so far, the codebase is available on GitHub and tagged as [0.0.17](https://github.com/josegonzalez/cakeadvent-2016/tree/0.0.17).

Awh yis, our custom application routing layer is complete, and our blog is looking a bit sharper now. We still have a few more features to fill in, but for our next post, we'll take a look optimizing email sends for password resets.

Be sure to follow along via twitter on [@savant](https://twitter.com/savant). If you'd like to subscribe to this blog, you may follow the [rss feed here](/atom.xml). Also, all posts in the series will be conveniently linked on the sidebar of every post in the 2016 CakeAdvent Calendar. Come back tomorrow for more delicious content.
