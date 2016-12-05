---
  title:       "Preparing our Posts Admin"
  date:        2016-12-05 00:23
  description: ""
  category:    other
  tags:
    - admin
    - crud
    - routing
    - cakeadvent-2016
    - cakephp
  comments:    true
  sharing:     true
  published:   true
  layout:      post
  disable_advertisement: true
  series:      CakeAdvent-2016
  og_image:    /images/2016/12/05/generated-posts-admin.png
---

A friend of mine asked for a custom website, so here I am, writing a custom cms. I know, there are plenty of systems out there that would handle his needs, but it's also a good excuse to play around with CakePHP 3, so here we are.

> For the lazy, the codebase we'll be working on will be available on [GitHub](https://github.com/josegonzalez/cakeadvent-2016). I will be pushing each set of changes on the date when each blog post in this series is published. No cheating!

## Aliasing / to `PostsController::home`

In the previous blog post, we decided to alias the `/` route to the `PostsController::index()` action. Since we still need that action for the admin dashboard, lets make a new action called `home` and use *that* as the alias. We'll start by modifying the `config/routes.php` file, and setting the default route to the following:

```php
$routes->connect('/', ['controller' => 'Posts', 'action' => 'home']);
```

Next, we need to map that action in our controller to something real. Instead of defining a `home` action, for now I'm just going to add an extra mapping of `home` to the `Crud.Index` action. We'll use a new `PostsController::initialize()` method to handle this:

```php
    /**
     * Initialization hook method.
     *
     * Use this method to add common initialization code like loading components.
     *
     * e.g. `$this->loadComponent('Security');`
     *
     * @return void
     */
    public function initialize()
    {
        parent::initialize();
        $this->Crud->mapAction('home', 'Crud.Index');
        $this->Auth->allow(['home']);
    }
```

Finally, we'll want to set the proper template for the action. Copy the file `src/Template/Posts/index.ctp` to `src/Template/Posts/home.ctp`. We can decide what to display here later.

Once thats done, commit your changes:

```shell
git config/routes.php src/Controller/PostsController.php src/Template/Posts/home.ctp
git commit -m "Move / route to /posts/home"
```

## CrudView

This entire time, we've been leaning on the generated bake templates to decide what we want to show users. A powerful alternative to this is the `CrudView` plugin. `CrudView` is a counterpart to the `Crud` plugin in that it allows you to autogenerate views for actions contained in that plugin. It's pretty radical.

> While we *have* edited our `Users/edit.ctp` template, we haven't spent too much time there, so I think we can afford to drop our existing work.

To start off, lets enable `CrudView` for our PostsController. We'll do so by modifying our `AppController` to enable `CrudView` whenever we are in a current admin action. Start by adding the following property to your `AppController`:

```php
    /**
     * A list of actions where the CrudView.View
     * listener should be enabled. If an action is
     * in this list but `isAdmin` is false, the
     * action will still be rendered via CrudView.View
     *
     * @var array
     */
    protected $adminActions = [];
```

In `AppController::initialize()`, there is a check on `$this->isAdmin` when states whether or not we can enable the `CrudView` listener. We'll modify that to take our `adminActions` property into account.

```php
if ($this->isAdmin || in_array($this->request->action, $this->adminActions)) {
    $this->Crud->addListener('CrudView.View');
}
```

We'll also need to modify the `$isAdmin` variable in our `AppController::beforeFilter()` to take this into account.

```php
$isAdmin = $this->isAdmin || in_array($this->request->action, $this->adminActions);
```

> The above changes aren't necessary in later versions of josegonzalez/app - certainly not after 1.4.8. They are here in case you have an older version of the app skeleton.

Now that we have some of the groundwork laid out, we need to actually specify the `adminActions` property in our `PostsController`. I've set it to allow almost all crud-actions, except for the `view` action, which doesn't make sense for my admin panel.

```php
    /**
     * A list of actions where the CrudView.View
     * listener should be enabled. If an action is
     * in this list but `isAdmin` is false, the
     * action will still be rendered via CrudView.View
     *
     * @var array
     */
    protected $adminActions = ['index', 'add', 'edit', 'delete'];
```

Next, we'll need to allow access to these actions. Our admin panel won't be very useful if we can't see whats going on. I've also helpfully added the `delete` action, because we'll probably want to delete posts. Add the following to your `PostsController`:

```php
    /**
     * Check if the provided user is authorized for the request.
     *
     * @param array|\ArrayAccess|null $user The user to check the authorization of.
     *   If empty the user fetched from storage will be used.
     * @return bool True if $user is authorized, otherwise false
     */
    public function isAuthorized($user = null)
    {
        $action = $this->request->param('action');
        if (in_array($action, $this->adminActions) || $action == 'delete') {
            return true;
        }
        return parent::isAuthorized($user);
    }
```

And last but not least, lets remove all the baked `Posts` templates.

```shell
rm src/Template/Posts/index.ctp src/Template/Posts/add.ctp src/Template/Posts/edit.ctp src/Template/Posts/view.ctp
```

If you go to the `/posts` url now, you'll get a view similar to the following:

![workinggenerated posts admin](/images/2016/12/05/generated-posts-admin.png)

Pretty sweet. It doesn't match our `/users/edit` page - or really anything else - but we'll work on that later. For now, lets clean up that sidebar. We'll add the following logic to our `AppController::beforeFilter()` method, in the block that checks on whether the crud action is mapped or not.:

```php
$this->Crud->action()->config('scaffold.tables_blacklist', [
    'phinxlog',
    'muffin_tokenize_phinxlog',
    'post_attributes',
    'tokenize_tokens',
    'users',
]);
```

> For now, we won't have a link to the `/users/edit` page, but in the near future, it'll hopefully be possible to both add arbitary links to the sidebar as well as arbitrary links to the top navigation.

We have the beginnings of our admin dashboard, using CrudView. Let's save that up:

```shell
git add src/Controller/AppController.php src/Controller/PostsController.php src/Template/Posts/add.ctp src/Template/Posts/edit.ctp src/Template/Posts/index.ctp src/Template/Posts/view.ctp
git commit -m "CrudView now handles /posts admin panels"
```

--

> For those that may just want to ensure their codebase matches what has been done so far, the codebase is available on GitHub and tagged as [0.0.4](https://github.com/josegonzalez/cakeadvent-2016/tree/0.0.5).

This was a short post, but we actually did quite a bit of work. We now have a programmatic admin dashboard that can be melded to our use case in future posts. It's been a long week, and our CMS is starting to take shape. Tomorrow we'll look at modifying what exactly is shown on our `/posts` dashboard, and make sure our database tables line up with our needs.

Be sure to follow along via twitter on [@savant](https://twitter.com/savant). If you'd like to subscribe to this blog, you may follow the [rss feed here](/atom.xml). Also, all posts in the series will be conveniently linked on the sidebar of every post in the 2016 CakeAdvent Calendar. Come back tomorrow for more delicious content.

