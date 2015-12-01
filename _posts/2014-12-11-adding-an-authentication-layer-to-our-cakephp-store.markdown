---
  title:       "Adding an Authentication layer to our CakePHP Store"
  date:        2014-12-11 18:26
  description: "Part 2 of 7 in a series of posts designed to teach you how to use CakePHP 3 effectively"
  category:    cakephp
  tags:
    - cakeadvent-2014
    - cakephp
    - composer
  comments:    true
  sharing:     true
  published:   true
  layout:      post
  series:      CakeAdvent-2014
---

We already have basic scaffolding for our application, so lets get authentication working. First, we'll add the login/logout methods by modifying our bake skeleton. Add the following to your `app/config/bootstrap_cli.php`:

```php
use Cake\Event\Event;
use Cake\Event\EventManager;
use Cake\Utility\Hash;

EventManager::instance()->attach(function (Event $event) {
    $view = $event->subject;
    $name = Hash::get($view->viewVars, 'name');
    $isController = strpos($event->data[0], 'Bake/Controller/controller.ctp') !== false;
    if ($isController && $name == 'Users') {
        $view->viewVars['actions'] = ['login', 'logout', 'index', 'view', 'register', 'edit', 'delete'];
    }
}, 'Bake.beforeRender');
```

Now that this is set, we'll need action templates for our `login`, `logout`, and `register` methods. These do not come with CakePHP as they can be pretty specific, so we'll include some pretty basic ones.

Here is `app/src/Template/Bake/Element/Controller/login.ctp`:

```php
/**
 * Login method
 *
 * @return void
 */
public function login() {
    if ($this->request->is('post')) {
        $user = $this->Auth->identify();
        if ($user) {
            $this->Auth->setUser($user);
            return $this->redirect($this->Auth->redirectUrl());
        }
        $this->Flash->error(__('Invalid username or password, try again'));
    }
}
```

And here is `app/src/Template/Bake/Element/Controller/logout.ctp`:

```php
/**
 * Logout method
 *
 * @return void
 */
public function logout() {
    return $this->redirect($this->Auth->logout());
}
```

And finally `app/src/Template/Bake/Element/Controller/register.ctp` (which is simply `add.ctp` but with the action name changed):

```php
<% $compact = ["'" . $singularName . "'"]; %>

/**
 * Register method
 *
 * @return void
 */
  public function register() {
    $<%= $singularName %> = $this-><%= $currentModelName %>->newEntity($this->request->data);
    if ($this->request->is('post')) {
      if ($this-><%= $currentModelName; %>->save($<%= $singularName %>)) {
        $this->Flash->success('The <%= strtolower($singularHumanName) %> has been saved.');
        return $this->redirect(['action' => 'index']);
      } else {
        $this->Flash->error('The <%= strtolower($singularHumanName) %> could not be saved. Please, try again.');
      }
    }
<%
    $associations = array_merge(
      $this->Bake->aliasExtractor($modelObj, 'BelongsTo'),
      $this->Bake->aliasExtractor($modelObj, 'BelongsToMany')
    );
    foreach ($associations as $assoc):
      $association = $modelObj->association($assoc);
      $otherName = $association->target()->alias();
      $otherPlural = $this->_variableName($otherName);
%>
    $<%= $otherPlural %> = $this-><%= $currentModelName %>-><%= $otherName %>->find('list');
<%
      $compact[] = "'$otherPlural'";
    endforeach;
%>
    $this->set(compact(<%= join(', ', $compact) %>));
  }
```

You can rebake your UsersController now:

```shell
cd /vagrant/app

bin/cake bake controller users -f
```

We also need a login view template at `app/src/Template/Bake/Template/login.ctp`

```php
<div class="<%= $pluralVar %> form">
<?= $this->Flash->render('auth') ?>
<?= $this->Form->create() ?>
    <fieldset>
        <legend><?= __('Please enter your username and password') ?></legend>
        <?= $this->Form->input('username') ?>
        <?= $this->Form->input('password') ?>
    </fieldset>
<?= $this->Form->button(__('Login')); ?>
<?= $this->Form->end() ?>
</div>
```

And we need our `app/src/Template/Bake/Template/register.ctp`, which will just call out to the `form.ctp` element:

```php
<%
echo $this->element('form');
```

To create these new views, we can simply use bake. Note that if a bake template does not exist for a given action, a corresponding view template is not created. This means we won't have an empty `app/src/Template/Users/logout.ctp` generated, which is nice.

```shell
bin/cake bake view users -f
```

When users register themselves, we want to ensure they have correct data in the database. CakePHP exposes Validators for this exact purpose, and we'll add a custom validator to our `UsersTable` to handle this:

```php
// Also include `use Cake\Validation\Validator;` at the top of your class
public function validationDefault(Validator $validator) {
    return $validator
        ->notEmpty('username', 'A username is required')
        ->notEmpty('password', 'A password is required');
}
```

> We'll go into Validators in more detail in a future post. For now, just be aware that they exist and can be used on any type of data.

While we've templated out a bunch of stuff, we still need to actually handle login/logout. You can load the AuthComponent in your AppController::initialize() like so:

```php
public function initialize() {
    $this->loadComponent('Flash');
    $this->loadComponent('Auth', [
        // Where to redirect after a successful login
        'loginRedirect' => [
            'controller' => 'Products',
            'action' => 'index'
        ],
        // Where to redirect after a user logs out
        'logoutRedirect' => [
            'controller' => 'Products',
            'action' => 'index',
            'home'
        ]
    ]);
}
```

In previous CakePHP versions, you would use the beforeFilter, but in the current version, we load behaviors/components/helpers inside of the `initialize()` method of a class.

We also need to allow access to our logout action - as well as let users actually register. In all other actions, we'll currently allow *everything* to happen - and lock this down as we build out the application! We can do so by adding access to those methods from within our `AppController::beforeFilter()`:

```php
// Also include `use Cake\Event\Event;` at the top of your class
public function beforeFilter(Event $event) {
    parent::beforeFilter($event);
    if ($this->request->controller == 'Users') {
        $this->Auth->allow(['add', 'logout']);
    } else {
        $this->Auth->allow();
    }
}
```

One last thing is that we need to take care of password hashing. Since CakePHP 2, the framework does not automatically hash password fields. This is due to developers getting weird errors with non-user password fields being hashed (or not hashed!) with certain configurations. In CakePHP 3, we can handle this easily by adding a new setter method for the `password` field to our `app/src/Model/Entity/User.php` entity. Note that setter methods are prefixed by `_set` and the field is `UpperCamelCase`:

```php
// Also include `use Cake\Auth\DefaultPasswordHasher;` at the top of your class
protected function _setPassword($password) {
    return (new DefaultPasswordHasher)->hash($password);
}
```

And we now have a functioning authentication layer on top of our store application. A couple notes:

- We can no longer re-bake our user Entity or Table classes. Boo. A wise developer would crack open new bake templates and add in the appropriate hooks to include traits instead of adding methods, or even switch those methods to bake elements.
- It would be useful to create a shell to pre-seed users from random data or custom data. You may guess what the next blog post will concern :)

We'll cover those over the next few installment of CakeAdvent 2014. Be sure to follow along via twitter on [@savant](https://twitter.com/savant). If you'd like to subscribe to this blog, you may follow the [rss feed here](http://josediazgonzalez.com/atom.xml). Also, all posts in the series will be conveniently linked on the sidebar of every post in the 2014 CakeAdvent Calendar. Come back tomorrow for more delicious content.
