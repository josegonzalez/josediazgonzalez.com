---
  title:       "Customizing the Posts Dashboard with CrudView"
  date:        2016-12-06 11:28
  description: "Part 6 of a series of posts that will help you build out a personal CMS"
  category:    cakephp
  tags:
    - crud
    - navigation
    - cakeadvent-2016
    - cakephp
  comments:    true
  sharing:     true
  published:   true
  layout:      post
  disable_advertisement: true
  series:      CakeAdvent-2016
  og_image:    /images/2016/12/06/dope-admin-customizations.png
---

A friend of mine asked for a custom website, so here I am, writing a custom cms. I know, there are plenty of systems out there that would handle his needs, but it's also a good excuse to play around with CakePHP 3, so here we are.

> For the lazy, the codebase we'll be working on will be available on [GitHub](https://github.com/josegonzalez/cakeadvent-2016). I will be pushing each set of changes on the date when each blog post in this series is published. No cheating!

## Updating Plugins

Before we continue, lets be sure we've updated all our plugins. I like to do this each day so that I can get any bugfixes that come out for libraries my application depends upon. In this case, there are a few bugfixes for some CakePHP plugins, so we'll grab those with the following `composer` command:

```php
composer update
```

Typically you would run tests at this stage, but since we have _yet_ to write any, that isn't necessary.

Let's commit any updates:

```shell
git add composer.lock
git commit -m "Update unpinned dependencies"
```

> You should always verify your application still works after upgrading dependencies.

## Modifying the Utility Navigation Bar

The new version of CrudView that we just upgraded to has support for managing the navigation in the upper-right. I'm going to use this to add a logout button. Add the following to your `AppController::beforeFilter()` method in the `if ($this->Crud->isActionMapped()) {` section:

```php
$this->Crud->action()->config('scaffold.utility_navigation', [
    new \CrudView\Menu\MenuItem(
        'Log Out',
        ['controller' => 'Users', 'action' => 'logout']
    )
]);
```

We can use the following classes for defining a utility navigation bar:

- `\CrudView\Menu\MenuDropdown`: Can be used to setup dropdown menus
- `\CrudView\Menu\MenuDivider`: Can be used as a separator in dropdown menus
- `\CrudView\Menu\MenuItem`: A menu item link. Takes the same options as `HtmlHelper::link()`

Pretty easy way for us to customize what is being shown, and as the `MenuItem` takes all the same options as `HtmlHelper::link()`, it should be quite useful.

## Modifying the Sidebar Navigation

The new version of CrudView that we just upgraded to has support for managing the navigation on the sidebar. We can disable it, blacklist tables, or control the exact contents. We previously used the table blacklist, but I'm going to replace this with a completely controled sidebar. Add the following to your `AppController::beforeFilter()` method in the `if ($this->Crud->isActionMapped()) {`:

```php
$this->Crud->action()->config('scaffold.sidebar_navigation', [
    new \CrudView\Menu\MenuItem(
        'Posts',
        ['controller' => 'Posts', 'action' => 'index']
    ),
    new \CrudView\Menu\MenuItem(
        'Profile',
        ['controller' => 'Users', 'action' => 'edit']
    ),
]);
```

We can use the following classes for defining a utility navigation bar:

- `\CrudView\Menu\MenuDivider`: Can be used as a separator in dropdown menus
- `\CrudView\Menu\MenuItem`: A menu item link. Takes the same options as `HtmlHelper::link()`

A useful addition would be a `MenuList`, so we can have groups of sidebar items, though for now this is good enough.

## Customizing `/posts` fields

If you look at the existing `/posts` page, you'll see there are quite a few fields there that we might not want. Ideally, the following is shown:

- `id`
- `title`
- `status`
- `published_date`
- actions list

Looking at the list, we're missing the following fields from our `posts` table:

- `title`
- `published_date`

We can add those pretty easily via the migrations plugin. I ran the following to add the fields:

```shell
bin/cake bake migration add_admin_field_to_posts title:string published_date:datetime
bin/cake migrations migrate
```

Simple enough. Now we'll scope the fields being shown to just those that we want. Rather than adding a bunch of custom callbacks directly to our `PostsController`, lets create a `PostsListener` in `src/Listener/PostsListener.php`. Here is mine, with the changes needed to scope our `/posts` page:

```php
<?php
namespace App\Listener;

use Cake\Event\Event;
use Crud\Listener\BaseListener;

/**
 * Posts Listener
 */
class PostsListener extends BaseListener
{
    /**
     * Callbacks definition
     *
     * @return array
     */
    public function implementedEvents()
    {
        return [
            'Crud.beforeHandle' => 'beforeHandle',
        ];
    }

    /**
     * Before Handle
     *
     * @param \Cake\Event\Event $event Event
     * @return void
     */
    public function beforeHandle(Event $event)
    {
        if ($this->_controller()->request->action === 'index') {
            $this->beforeHandleIndex($event);

            return;
        }
    }

    /**
     * Before Handle Index Action
     *
     * @param \Cake\Event\Event $event Event
     * @return void
     */
    public function beforeHandleIndex(Event $event)
    {
        $this->_action()->config('scaffold.fields', [
            'id',
            'title',
            'status',
            'published_date',
        ]);
    }
}
```

Now we need to load it in our `PostsController::initialize()` method:

```php
$this->Crud->addListener('Users', 'App\Listener\PostsListener');
```

Pretty neat.

## Modifying field output using formatters

One cool thing about CrudView is that we can specify how we want fields to look like on templates by using custom formatters. Rather than show the status as just text, I'm going to switch it to use a bootstrap label depending upon the content of the text.

```php
$this->_action()->config('scaffold.fields', [
    'id',
    'title',
    'status' => [
      'formatter' => function ($name, $value, $entity) {
          $type = $value == 'active' ? 'success' : 'default';
          return sprintf('<span class="label label-%s">%s</span>', $type, $value);
      },
    ],
    'published_date',
]);
```

![dope admin panel](/images/2016/12/06/dope-admin-customizations.png)

You can also use an element as a `formatter`, though please refer to the documentation on CrudView for further details.

Lets save where we are for now.

```shell
git add config/Migrations/20161206204729_AddAdminFieldToPosts.php config/Migrations/schema-dump-default.lock src/Controller/AppController.php src/Controller/PostsController.php src/Listener/PostsListener.php
git commit -m "Updated /posts dashboard"
```

---

> For those that may just want to ensure their codebase matches what has been done so far, the codebase is available on GitHub and tagged as [0.0.6](https://github.com/josegonzalez/cakeadvent-2016/tree/0.0.6).

We now have a reasonable looking `/posts` page with a few lines of code. Super Dope! Our next job is to work on the possibility of having different post types, how to model them in code, and how they relate to our database structure.

Be sure to follow along via twitter on [@savant](https://twitter.com/savant). If you'd like to subscribe to this blog, you may follow the [rss feed here](/atom.xml). Also, all posts in the series will be conveniently linked on the sidebar of every post in the 2016 CakeAdvent Calendar. Come back tomorrow for more delicious content.

