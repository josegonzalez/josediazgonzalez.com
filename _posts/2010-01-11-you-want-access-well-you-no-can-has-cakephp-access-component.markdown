---
  title: You want access? Well you no can has! - A CakePHP AccessComponent
  category:    cakephp
  tags:
    - access
    - authorization
    - authsome-plugin
    - cakephp
    - component
    - github
  description: One of the things I am working on is Authentication and Access Control. While Authsome Component takes care of authentication, we still need something more.
  comments:    true
  sharing:     true
  published:   true
  layout:      post
---

My latest side-project is an app for managing file uploads - you might even be able to guess what it is by checking my latest updates on Github - which has some pretty specific requirements. It therefore has some functionality that might be pretty useful in other applications, so over the next few days I'll be releasing some of the more interesting ones as gists (and forking existing projects where necessary).

One of the things I am working on is Authentication and Access Control. The [CakePHP Authsome Plugin](http://github.com/felixge/cakephp-authsome) by the [Debuggable Folks - Felix Geisendörfer and Tim Koschützki](http://debuggable.com/) - handles application EXTREMELY well. It's a heck of a lot simpler to setup than the built-in [AuthComponent](http://api.cakephp.org/class/auth-component) for certain apps, although it does require me to handle stuff that the AuthComponent does for me. Like allowed and denied actions.

To setup AuthComponent, you might do something similar to the following:

```php
class UsersController extends AppController {
    public $name = 'Users';
    public $components = array('Auth');

    public function beforeFilter() {
        parent::beforeFilter();
        $this->Auth->loginAction = array('admin' => false, 'controller' => 'users', 'action' => 'login');
    }

    public function isAuthorized() {
        if ($this->Auth->user()) {
            $this->Auth->deny('login', 'register', 'success', 'forgot_password', 'reset_password');
        } else {
            $this->Auth->deny('dashboard', 'logout', 'change_password');
        }
    }
}
```

This is pretty self-explanatory, but it takes a bit of thinking to setup. Since this is a fairly simple application - or at least I don't want to make stuff like Authentication and Authorization complex - I went with the  [Authsome Plugin](http://github.com/felixge/cakephp-authsome) instead though. Here it is, pretending to emulate the AuthComponent as best it can:

```php
class AppController extends Controller {
    public $components = array(
        'Authsome.Authsome' => array(
            'model' => 'User',
            'configureKey' => 'Auth',
            'sessionKey' => 'Auth',
            'cookieKey' => 'Auth',
        )
    );
```

Isn't it neat? Unfortunately, it does not handle Authorization. Sucks as my requirements are really simple.

 - You need to be an administrator to access a resource
 - You need to be authenticated to access a resource
 - You need to NOT be authenticated to access a resource
 - You are denied access to the resource

At the moment, I only have those 4 requirements - although the first should really be something along the lines of "you need to be a part of this group to access a resource" - so I coded up a [plugin component](https://github.com/josegonzalez/cakephp-sanction) to do it. And here it is in use:

```php
class ModerationsController extends AppController {
    public $name = 'Moderations';
    public $components = array('Access' => array('admin_required' => array('*')));

    public function index() { /* SNIP */ }
    public function user_queue() { /* SNIP */ }
    public function ignored_users() { /* SNIP */ }
    public function upload_queue() { /* SNIP */ }
}
```

You need admin access to get at anything in the above controller :)

```php
class MailsController extends AppController {
    public $name = 'Mails';
    public $components = array(
        'Access' => array('denied' => array('*'))
        'SwiftMailer');
    public $uses = array();
}
```

You no can has access! This is actually a utility Controller I use to hack my way around using the SwiftMailerComponent in a Model :P . Yes, I feel naughty.

```php
class UsersController extends AppController{
    public $name = 'Users';
    public $helpers = array('Gravatar');
    public $components = array(
        'Access' => array(
            'auth_denied' => array('login', 'register', 'success', 'forgot_password', 'reset_password'),
            'auth_required' => array('dashboard', 'logout', 'change_password')));

    public function index() { /* SNIP */ }
    public function login() { /* SNIP */ }
    public function logout() { /* SNIP */ }
    public function register() { /* SNIP */ }
    public function change_password() { /* SNIP */ }
    public function forgot_password() { /* SNIP */ }
    public function reset_password($username = null, $key = null) { /* SNIP */ }
    public function success() { /* SNIP */ }
    public function dashboard() { /* SNIP */ }
    public function profile($username = null) { /* SNIP */ }
}
```

You can even mix and match whether or not you need to be un-authenticated or authenticated to perform an action. Or anything else for that matter.

So far, the component works pretty well for my use-case, and I figure others might have similar use-cases, where they would like to use AuthSome Authentication, have a very simple user/group setup, but would need to worry about Authorization. I know I've built apps that were pretty much like this, where there isn't a need for ACL and I found myself screwing around with `Controller::beforeFilter()` methods.

_NOTE: By default, this component works on the initialization of the application, meaning that it works before the `Controller::beforeFilter()` action. This means that if you don't set the callback parameter to "startup", then it CANNOT be used in the AppController. You can still set it to "startup" even if using it in a specific Controller in case you have some `Controller::beforeFilter()` that needs to occur though._

A possible road to go down is to match actions via regular expressions, meaning that one COULD then support multiple groups of users with Prefixed Routes (a feature of 1.3) extremely easily. Anyone want to jump in and add that for me? :)

[The code is available as a gist on github, so go ahead and implement anything you need to :)](http://gist.github.com/276000)
