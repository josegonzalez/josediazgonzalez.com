---
  title:       "Unifying our admin dashboard views"
  date:        2016-12-11 10:51
  description: "Part 11 of a series of posts that will help you build out a personal CMS"
  category:    cakephp
  tags:
    - events
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

## Updating Plugins

Before we continue, lets be sure we've updated all our plugins. I like to do this each day so that I can get any bugfixes that come out for libraries my application depends upon. In this case, there are a few bugfixes for some CakePHP plugins, so we'll grab those with the following `composer` command:

```shell
composer update
```

Typically you would run tests at this stage, but since we have _yet_ to write any, that isn't necessary.

Let's commit any updates:

```shell
git add composer.lock
git commit -m "Update unpinned dependencies"
```

> You should always verify your application still works after upgrading dependencies.

## Today's todolist

We'll take care of the following two items today.

- The login screen looks different from the rest of the site.
- The `/users/edit` page has the wrong look and wrong sidebar.
- The `/users/forgot-password` and `/users/reset-password` pages has the wrong look and wrong sidebar.

## Using CrudView for the Login Page

First, lets make sure that we are using `CrudView` for the login action. I added the following property to my `UsersController`:

```php
/**
 * A list of actions where the CrudView.View
 * listener should be enabled. If an action is
 * in this list but `isAdmin` is false, the
 * action will still be rendered via CrudView.View
 *
 * @var array
 */
protected $adminActions = ['login'];
```

Next, we'll want to delete the `src/Template/Users/login.ctp` and `src/Template/Users/add.ctp` files. This will force `CrudView` to take control. Once that is done, we'll also need to set a view for the action. CrudView does not currently come with a view for the login action, so we'll repurpose the `CrudView.add.ctp` template. I added the following to my `UsersListener::beforeHandle()`:

```php
if ($event->subject->action === 'login') {
    $this->beforeHandleLogin($event);

    return;
}
```

And finally, here is my `UsersListener::beforeHandleLogin()`:

```php
/**
 * Before Handle Login Action
 *
 * @param \Cake\Event\Event $event Event
 * @return void
 */
public function beforeHandleLogin(Event $event)
{
    $this->_controller()->set([
        'viewVar' => 'login',
        'login' => null,
    ]);
    $this->_controller()->viewBuilder()->template('add');
    $this->_action()->config('scaffold.page_title', 'Login');
    $this->_action()->config('scaffold.fields', [
        'email',
        'password',
    ]);
    $this->_action()->config('scaffold.viewblocks', [
        'actions' => ['' => 'text'],
    ]);
    $this->_action()->config('scaffold.sidebar_navigation', false);
    $this->_action()->config('scaffold.disable_extra_buttons', true);
    $this->_action()->config('scaffold.submit_button_text', 'Login');
}
```

All of these options are available via CrudView, but check out the docs if you have any questions about them. You should be able to see a `/users/login` page with our normal CrudView styling now.

I'm committing my changes now:

```shell
rm src/Template/Users/add.ctp src/Template/Users/login.ctp
git rm src/Template/Users/add.ctp src/Template/Users/login.ctp
git add src/Controller/UsersController.php src/Listener/UsersListener.php
git commit -m "Use CrudView to template out the login page"
```

## Using CrudView for the Account Page

This is going to be pretty similar to the login page. Let's add `edit` to the `UsersController::$adminActions` property.

```php
/**
 * A list of actions where the CrudView.View
 * listener should be enabled. If an action is
 * in this list but `isAdmin` is false, the
 * action will still be rendered via CrudView.View
 *
 * @var array
 */
protected $adminActions = [
    'edit',
    'login'
];
```

Next, we'll want to delete the `src/Template/Users/edit.ctp`. To customize the view, we can modify our `UsersListener::beforeHandleEdit()`.

```php
/**
 * Before Handle Edit Action
 *
 * @param \Cake\Event\Event $event Event
 * @return void
 */
public function beforeHandleEdit(Event $event)
{
    $userId = $this->_controller()->Auth->user('id');
    $event->subject->args = [$userId];

    $this->_action()->saveOptions(['validate' => 'account']);
    $this->_action()->config('scaffold.page_title', 'Profile');
    $this->_action()->config('scaffold.disable_extra_buttons', true);
    $this->_action()->config('scaffold.viewblocks', [
        'actions' => ['' => 'text'],
    ]);
    $this->_action()->config('scaffold.fields', [
        'email',
        'password' => [
            'required' => false,
        ],
        'confirm_password' => [
            'type' => 'password',
        ],
        'avatar' => [
            'type' => 'file'
        ],
    ]);
}
```


ou should be able to see a `/users/edit` page with our normal CrudView styling now. One thing that is missing is the profile image embed. That's unfortunately non-trivial to insert into CrudView at the moment, so we are skipping that.

Commit!

```shell
rm src/Template/Users/edit.ctp
git rm src/Template/Users/edit.ctp
git add src/Controller/UsersController.php src/Listener/UsersListener.php
git commit -m "Use CrudView to template out the edit page"
```

## Using CrudView for the Password Reset Flow

This is more or less a rehash of the above. Lets start by deleting the `src/Template/Users/forgot_password.ctp` and `src/Template/Users/reset_password.ctp` files. Next, update the `UsersController::$adminActions` property to include these to actions:

```php
/**
 * A list of actions where the CrudView.View
 * listener should be enabled. If an action is
 * in this list but `isAdmin` is false, the
 * action will still be rendered via CrudView.View
 *
 * @var array
 */
protected $adminActions = [
    'edit',
    'login',
    'forgotPassword',
    'resetPassword',
];
```

As always, we'll need to update `UsersController::beforeHandle()` with new sections for our specific actions:

```php
if ($event->subject->action === 'forgotPassword') {
    $this->beforeHandleForgotPassword($event);

    return;
}
if ($event->subject->action === 'resetPassword') {
    $this->beforeHandleResetPassword($event);

    return;
}
```

Lastly, here is the code for the above two methods.

```php
/**
 * Before Handle ForgotPassword Action
 *
 * @param \Cake\Event\Event $event Event
 * @return void
 */
public function beforeHandleForgotPassword(Event $event)
{
    $this->_controller()->set([
        'viewVar' => 'forgotPassword',
        'forgotPassword' => null,
    ]);
    $this->_controller()->viewBuilder()->template('add');
    $this->_action()->config('scaffold.page_title', 'Forgot Password?');
    $this->_action()->config('scaffold.fields', [
        'email',
    ]);
    $this->_action()->config('scaffold.viewblocks', [
        'actions' => ['' => 'text'],
    ]);
    $this->_action()->config('scaffold.sidebar_navigation', false);
    $this->_action()->config('scaffold.disable_extra_buttons', true);
    $this->_action()->config('scaffold.submit_button_text', 'Send Password Reset Email');
}
```

```php
/**
 * Before Handle Login Action
 *
 * @param \Cake\Event\Event $event Event
 * @return void
 */
public function beforeHandleLogin(Event $event)
{
    $this->_controller()->set([
        'viewVar' => 'login',
        'login' => null,
    ]);
    $this->_controller()->viewBuilder()->template('add');
    $this->_action()->config('scaffold.page_title', 'Login');
    $this->_action()->config('scaffold.fields', [
        'email',
        'password',
    ]);
    $this->_action()->config('scaffold.viewblocks', [
        'actions' => ['' => 'text'],
    ]);
    $this->_action()->config('scaffold.sidebar_navigation', false);
    $this->_action()->config('scaffold.disable_extra_buttons', true);
    $this->_action()->config('scaffold.submit_button_text', 'Login');
}
```

Let's commit, as we're done with all our edits for today.

```shell
rm src/Template/Users/forgot_password.ctp src/Template/Users/reset_password.ctp
git rm src/Template/Users/forgot_password.ctp src/Template/Users/reset_password.ctp
git add src/Controller/UsersController.php src/Listener/UsersListener.php
git commit -m "Use CrudView for password reset flow"
```

---

> For those that may just want to ensure their codebase matches what has been done so far, the codebase is available on GitHub and tagged as [0.0.11](https://github.com/josegonzalez/cakeadvent-2016/tree/0.0.11).

Our users controller is now fully under the control of CrudView! We'll take care of some weird ux issues when creating posts tomorrow.

Be sure to follow along via twitter on [@savant](https://twitter.com/savant). If you'd like to subscribe to this blog, you may follow the [rss feed here](/atom.xml). Also, all posts in the series will be conveniently linked on the sidebar of every post in the 2016 CakeAdvent Calendar. Come back tomorrow for more delicious content.
