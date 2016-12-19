---
  title:       "Cosmetic Admin Cleanup"
  date:        2016-12-19 11:31
  description: "Part 19 of a series of posts that will help you build out a personal CMS"
  category:    cakephp
  tags:
    - crud-view
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

## Errata from previous post

The connected routes in `config/routes.php` for `/forgot-password` and `/reset-password` were incorrect and should be as follows

```php
$routes->connect('/forgot-password', ['controller' => 'Users', 'action' => 'forgotPassword']);
$routes->connect('/reset-password/*', ['controller' => 'Users', 'action' => 'resetPassword']);
```

Thanks to those who've pointed out my derps. These fixes are available as the first commit in the current release.

## Cosmetic Cleanup

There are a few things that currently irk me about the admin panel:

- We are duplicating navigation in the header and sidebar
- The default header link on the top-right when logged out is the `logout` link.
- The login redirect goes to `/`, when it should go to the `/admin/posts` page. The logout redirect should just go to the logout page.
- We're showing a link to the `view` action on the `/admin/posts` page but we should not.
- We're showing a link to the `home` action on the `/admin/posts/edit` page but we should not.

Let's fix that.

### De-duplicating Navigation Links

We can very easily combine our navigation by modifying the `scaffold.utility_navigation` crud config option to include the `scaffold.sidebar_navigation` elements. I'm going to refactor this into a helper method in our `AppController` class:

```php
/**
 * Retrieves the navigation elements for the page
 *
 * @return array
 */
protected function getUtilityNavigation()
{
    return [
        new \CrudView\Menu\MenuItem(
            'Posts',
            ['controller' => 'Posts', 'action' => 'index']
        ),
        new \CrudView\Menu\MenuItem(
            'Profile',
            ['controller' => 'Users', 'action' => 'edit']
        ),
        new \CrudView\Menu\MenuItem(
            'Log Out',
            ['controller' => 'Users', 'action' => 'logout']
        )
    ];
}
```

Next, we can update our `AppController::beforeFilter()` to remove the `scaffold.sidebar_navigation` and `scaffold.tables_blacklist` configuration, replacing it with

```php
$this->Crud->action()->config('scaffold.utility_navigation', $this->getUtilityNavigation());
```

This will move our navigation to the top, but will also re-enable the default sidebar. Let's fix that next. For now, commit our changes:

```shell
git add src/Controller/AppController.php
git commit -m "Move sidebar navigation to header"
```

### Disabling the Sidebar

This is pretty simple. We've already done this for a few actions in the `UsersController`, but we'll want to do this more globally. Add the following line to your `AppController::beforeFilter()`, in the block checking if `Crud::isActionMapped()`.

```php
$this->Crud->action()->config('scaffold.sidebar_navigation', false);
```

Now your entire page layout should be taken up by the contents of the view, sans sidebar.

You can also remove this setting from your `UsersListener`, as we are handling it globally now. The following methods will be updated:

- `UsersListener::beforeHandleLogin()`
- `UsersListener::beforeHandleResetPassword()`
- `UsersListener::beforeHandleForgotPassword()`

Time to commit:

```shell
git add src/Controller/AppController.php src/Listener/UsersListener.php
git commit -m "Disable the sidebar navigation completely"
```

### Switching header links for logged out users

We should almost certainly not be showing the "Posts", "Profile", and "Log Out" utility navigation links to logged out users. Instead, lets show a link to login and start the forgot password flow to logged out users. I added the following to the beginning of my `AppController::getUtilityNavigation()` method:

```php
if ($this->Auth->user('id') === null) {
    return [
        new \CrudView\Menu\MenuItem(
            'Forgot Password?',
            ['controller' => 'Users', 'action' => 'forgotPassword']
        ),
        new \CrudView\Menu\MenuItem(
            'Login',
            ['controller' => 'Users', 'action' => 'login']
        ),
    ];
}
```

Nothing obtuse here, it's all pretty straightforward. We'll commit our changes

```shell
git add src/Controller/AppController.php
git commit -m "Show alternative utility navigation to logged out users"
```

### Fixing the login/logout redirects

This is just a matter of changing configuration in our `AppController::loadAuthComponent()`, and very specifically the `loginRedirect` and `logoutRedirect` configuration options. Here is the full method:

```php
/**
 * Configures the AuthComponent
 *
 * @return void
 */
protected function loadAuthComponent()
{
    $this->loadComponent('Auth', [
        'authorize' => ['Controller'],
        'loginAction' => [
            'plugin' => null,
            'prefix' => false,
            'controller' => 'Users',
            'action' => 'login'
        ],
        'loginRedirect' => [
            'plugin' => null,
            'prefix' => false,
            'controller' => 'Posts',
            'action' => 'index',
        ],
        'logoutRedirect' => [
            'plugin' => null,
            'prefix' => false,
            'controller' => 'Users',
            'action' => 'login',
        ],
        'authenticate' => [
            'all' => [
                'fields' => ['username' => 'email', 'password' => 'password'],
            ],
            'Form',
        ]
    ]);
}
```

You know the drill, save your changes:

```shell
git add src/Controller/AppController.php
git commit -m "Properly redirect users on login/logout"
```

### Removing the `view` link from our post action list

The `scaffold.actions_blacklist` Crud config option can be used to remove an action from being linked to. We'll add the following to our `PostsListener::beforeHandleIndex()` method:

```php
$this->_action()->config('scaffold.actions_blacklist', [
    'view',
]);
```

Yay commit!

```shell
git add src/Listener/PostsListener.php
git commit -m "Disable the view action link"
```

### Removing the `home` link from our post action list

The `scaffold.actions_blacklist` Crud config option can be used to remove an action from being linked to. Add the following to our `PostsListener::beforeHandleEdit()` method:

```php
/**
 * Before Handle Edit Action
 *
 * @param \Cake\Event\Event $event Event
 * @return void
 */
public function beforeHandleEdit(Event $event)
{
    $this->_action()->config('scaffold.actions_blacklist', [
        'home',
    ]);
}
```

We'll need to add the following to `PostsListener::beforeHandle()` in order to trigger this as well:

```php
if ($this->_request()->action === 'edit') {
    $this->beforeHandleEdit($event);

    return;
}
```

Be sure to save your changes

```shell
git add src/Listener/PostsListener.php
git commit -m "Disable the home action link"
```

---

> For those that may just want to ensure their codebase matches what has been done so far, the codebase is available on GitHub and tagged as [0.0.19](https://github.com/josegonzalez/cakeadvent-2016/tree/0.0.19).

Our admin panel is in pretty good shape now - we could certainly try and spruce up the edit page for photo posts, but we'll leave that for another day. Tomorrow, we'll try add "sellable" photos to our CMS.

Be sure to follow along via twitter on [@savant](https://twitter.com/savant). If you'd like to subscribe to this blog, you may follow the [rss feed here](/atom.xml). Also, all posts in the series will be conveniently linked on the sidebar of every post in the 2016 CakeAdvent Calendar. Come back tomorrow for more delicious content.
