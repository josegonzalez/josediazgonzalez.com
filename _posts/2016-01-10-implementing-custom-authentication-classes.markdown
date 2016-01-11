---
  title:       "Implementing Custom Authenication Classes"
  date:        2016-01-10 12:00
  description: "Implementing both Form Authentication and a custom Authentication class in CakePHP"
  category:    cakephp
  tags:
    - cakephp
    - scaffold
    - authenication
  comments:    true
  sharing:     true
  published:   true
  layout:      post
  series:      Media Manager
---

As with any application, deployment is always something you need to think about. How does your application work with the existing infrastructure?

One thing that SeatGeek does is we provide a single sign-on solution to all our applications. This allows developers building backend dashboards to ignore the hassles of needing to write any of the following for their application:

- Login/Logout pages
- Forgot/Reset Password flows
- Proper password hashing
- User management (adding/deleting users, admin users, etc.)

When someone at SeatGeek logs into an admin panel, the web server - in our case Nginx - redirects them to a page where they can authenticate against our organization. Once the user authenticates against our organization, the web server sets a few environment parameters with information about that user:

- first/last name
- email address
- a user id from the single sign-on service
- teams that user is attached to

Over the years, we've realized that this is the absolute minimum amount of information necessary to identify a user:

- We can now display something sensible in the UI when referring to that logged in user
- Email notifications can be sent if necessary (though we try to handle this in the UI itself)
- We can associate actions that need to be audited with a specific user in case we need to figure out who did what
- We can limit access to certain dashboards or abilities based on what teams a user is associated with

Since this is an open source project, I still want to let people use the built-in CakePHP Auth code. Thus the challenge becomes "How do I integrate our existing Auth service with CakePHP, while still allowing optional Form-based Authentication?"

## HeaderAuthenticate

Let's start by building a simple `Authenticate` class. Why not an `Authorize` class?

- `Authenticate` classes are used by CakePHP to denote whether or not a user is logged into your application
- `Authorize` classes are used by CakePHP to see whether an authenticated user has access to a particular controller/action pair.

Since I am using information set by the webserver in the headers to identify the user, I will call it `HeaderAuthenticate` and have it extend `BasicAuthenticate` [^1]. Here is the class skeleton:

```php
<?php
namespace App\Auth;

use Cake\Auth\BasicAuthenticate;
use Cake\Network\Request;

class HeaderAuthenticate extends BasicAuthenticate
{
}
?>
```

Because I extend `BasicAuthenticate`, the only method I have to implement is `getUser(Request $request)`. Why? Because the `authenticate` method calls this automatically, and that is the only method custom `Authenticate` classes need to implement. The `AuthComponent` will automatically call this method when checking requests, so it seemed to me like a good place to start.

First, I'll add a `$_defaultConfig` class property to override the one from `BasicAuthenticate`:

```php
    protected $_defaultConfig = [
       'fields' => [
           'username' => 'username',
           'password' => 'password',
           'name' => 'name',
           'email' => 'email',
       ],
       'headers' => [
           'username' => 'AUTH_USERNAME',
           'name' => 'AUTH_NAME',
           'email' => 'AUTH_EMAIL',
       ],
       'userModel' => 'Users',
       'scope' => [],
       'finder' => 'all',
       'contain' => null,
       'passwordHasher' => 'Default'
    ];
```

A few things:

- Most, if not all, CakePHP core classes that can be instantiated use the [`InstanceConfigTrait`](/2015/12/22/using-instance-config-trait-for-object-configuration/). This means that we automatically get access to the configured data when setting a `$_defaultConfig` property and using the `$this->config()` method. Check out the linked blog post for more information.
- I set a few new custom fields there. These are fields that I will use in my `Authenticate` class to denote what data goes where when saving my user entity.
- I have a few headers mapped. These headers are used by our single sign-on solution, and mapping them to fields we are using in our entity makes sense to me.

Next comes the `getUser(Request $request)` method. The basic gist of this class will be to see if the incoming data maps to a specific user. If it does not, then we will create a user and return that data. I'm going to split this logic out into two methods, one of which (`_getUser`) will handle creating a user if necessary, and the other (`getUser`) will wrap this method to ensure we properly handle responses. Here are the two methods:

```php

    /**
     * Authenticate a user using custom headers.
     *
     * If the user does not exist in the database but
     * the correct header was passed, simply create the
     * user using the provided header data
     *
     * @param \Cake\Network\Request $request Request object.
     * @return mixed Either false or an array of user information
     */
    public function getUser(Request $request)
    {
        // The same as doing the following but with less overhead:
        //   $config = $this->config();
        $config = $this->_config;

        // Bail out if the username header doesn't exist
        $username = $request->header($config['headers']['username']);
        if (empty($username)) {
            return false;
        }

        // Actually get the user mapping to the current request
        $result = $this->_getUser($request);
        if (empty($result)) {
            return false;
        }

        // *Never* let the password field be set in the session
        $result->unsetProperty($config['fields']['password']);

        // Return the array of data (entities aren't stored in the session)
        return $result->toArray();
    }


    /**
     * Retrieves or creates a user based on header data
     *
     * @param \Cake\Network\Request $request Request object.
     * @return mixed Either false or an array of user information
     */
    protected function _getUser(Request $request)
    {
        // The same as doing the following but with less overhead:
        //   $config = $this->config();
        $config = $this->_config;

        // We don't need to check if this is empty because we assume
        // this method will only be called if there is a value
        $username = $request->header($config['headers']['username']);

        // This `_query()` method comes from BaseAuthenticate, and more or less
        // just sets up the find query. The `$username` var here will be mapped
        // to `fields.username` from our config.
        $result = $this->_query($username)->first();
        if (!empty($result)) {
            return $result;
        }

        // Construct the saved data for the new entity
        // The password field is empty because this user
        // has no password
        $data = [
            $config['fields']['username'] => $username,
            $config['fields']['password'] => '',
            $config['fields']['name'] => $request->header($config['headers']['name']),
            $config['fields']['email'] => $request->header($config['headers']['email']),
        ];

        // Save the new entity, and return the result if possible
        $table = TableRegistry::get($config['userModel']);
        $result = $table->newEntity($data);
        if (!$table->save($result)) {
            return false;
        }
        return $result;
    }
```

> Note that rather than explaining the above in paragraphs, I've commented the code inline. I don't normally do that in actual production code, as to me it makes it apparently that I need to refactor the methods into smaller, more manageable chunks.

## Login/Logout actions

Now, how do we setup authentication in our application? I hate writing custom actions for each app, so if possible I use a CrudAction. Let's do that by installing FriendsOfCake/crud-users:

```shell
# install the thing!
composer require friendsofcake/crud-users

# enable the thing!
bin/cake plugin load CrudUsers
```

This plugin is under heavy development, but provides two actions I'd rather not write code for, login and logout.

Next, we can create an extremely simple `UsersController` using `bake`:

```shell
bin/cake bake controller Users -t Crud
```

Next, lets ensure we configure it properly to handle the new login/logout actions. Add the following to the `UsersController`:

```php
    public function initialize()
    {
        parent::initialize();
        $this->Crud->mapAction('login', 'CrudUsers.Login');
        $this->Crud->mapAction('logout', 'CrudUsers.Logout');
    }

    // Remember to add the proper use statement at
    // the top of the class for this:
    //
    //   use Cake\Event\Event;
    public function beforeFilter(Event $event)
    {
        parent::beforeFilter($event);
        // Allow users to register and logout.
        // You should not add the "login" action to allow list. Doing so would
        // cause problems with normal functioning of AuthComponent.
        $this->Auth->allow(['logout']);
    }
```

Now that we've configured the login/logout actions, we need to configure the rest of our Authentication setup. I had to add the following to my `AppController::initialize()` to handle both my custom `HeaderAuthenticate` setup and `FormAuthenticate` installs.

```php
$this->loadComponent('Auth', [
    'authenticate' => [
        'Header' => [
            'fields' => [
                // this is where my github_id field comes into play
                'username' => 'github_id',
            ],
        ],
        'Form' => [
            'fields' => [
                // we don't have a username field, and users login with email
                'username' => 'email',
                'password' => 'password',
            ]
        ]
    ],
    'authorize' => ['Controller'],
]);
```

I also added the following to my `AppController::beforeFilter()` to allow access to the `PagesController::display` action. You *could* move it to that controller, I just prefer adding it here:

```php
$this->Auth->allow(['display']);
```

The last thing to place in your `AppController` is an `isAuthorized` method. What is this used for? When you configure the `AuthComponent` to use `Controller` for the `authorize` method, the `AuthComponent` asks the `Controller::isAuthorized()` method whether a specific `$user` has access to the given request. Here is what that method looks like:

```php
/**
 * Check if the provided user is authorized for the request.
 *
 * @param array|null $user The user to check the authorization of.
 *   If empty the user fetched from storage will be used.
 * @return bool True if $user is authorized, otherwise false
 */
public function isAuthorized($user)
{
    if (!empty($user)) {
        return true;
    }

    // Default deny
    return false;
}
```

Here are the contents of my `src/Template/Users/login.ctp` template file. It is pretty boring.

```php
<div class="users form">
    <?= $this->Flash->render('auth') ?>
    <?= $this->Form->create() ?>
        <fieldset>
            <legend><?= __('Please enter your username and password') ?></legend>
            <?= $this->Form->input('email') ?>
            <?= $this->Form->input('password') ?>
        </fieldset>
    <?= $this->Form->button(__('Login')); ?>
    <?= $this->Form->end() ?>
</div>
```

We're close!

## Data-model changes

When you setup authentication, you need to ensure you are automatically hashing passwords properly. In our case, we'll need a single new method in our `src/Model/Entity/User.php` entity:

```php
    /**
     * Setter for password field.
     * Automatically hashes incoming passwords
     *
     * @param string $password the password to hash
     * @return string
     */
    protected function _setPassword($password)
    {
        return (new \Cake\Auth\DefaultPasswordHasher)->hash($password);
    }
```

> I've taken the liberty of using the fully-namespaced function instead of a `use` statement at the top of the class. This seems to be one of the top things new CakePHP developers don't understand. CakePHP 3 has fully embraced all the modern PHP stuff, which includes namespaces. Read this [PHP.net FAQ](https://secure.php.net/manual/en/language.namespaces.faq.php) on them when you get a chance.

In CakePHP 3, the `_set*` and `_get*` methods are used for setting data on entities, and ensuring they go in/out in the right formats. In our case, whenever we set a new password, we need to ensure it's been hashed properly. Note that when you populate data into an entity, you can turn off the use of the setter methods with the `useSetters` option. This is turned off when hydrating entities from the database.

One thing I need to do is allow my `github_id` to be null. Users authenticating with an email/password will otherwise be unable to access my application. Boo. Here is how I generated the initial migration file:

```shell
bin/cake bake migration allow_nullable_github_ids_on_users
```

And here is what I shoved into the file:

```php
<?php
use Migrations\AbstractMigration;

class AllowNullableGithubIdOnUsers extends AbstractMigration
{
    public function change()
    {
        $table = $this->table('users');
        $table->changeColumn('github_id', 'integer', [
            'default' => null,
            'limit' => 11,
            'null' => true,
        ]);
        $table->update();
    }
}
?>
```

One other thing I noticed when testing was that the `github_id` field added a specific rule to my `UsersTable`, wherein it expects the `UsersTable` to be related to a `GithubsTable`. I don't have that, so I needed to remove both the relation in my `UsersTable::initialize()` and the associated rule in `UsersTable::buildRules()`.

## Testing it out

Well now that everything is set, if you deploy the app to the SeatGeek infrastructure, you can login and see the backend pages!

That doesn't help anyone else though. We never created a user, nor do we have a method of registration. My next post will cover creating a test user from the command-line, cleaning up our views a bit, and the first part of asset uploading.

Until then, you can see the results of today's work at [this github url](https://github.com/josegonzalez/media-manager/commit/5b605243dbff7f272cdc2940bdab4f5f023c4b32).

---

[^1]: The `BasicAuthenticate` core Authenticate class handles authenticate based on Basic Auth, so I figured a lot of the plumbing would be similar. If it's not, we can always switch it up.
