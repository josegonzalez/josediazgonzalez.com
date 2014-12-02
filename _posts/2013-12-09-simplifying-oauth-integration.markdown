---
  title:       "Simplifying OAuth integration"
  date:        2013-12-09 00:55
  description: "Rather than writing the same OAuth code for different projects, reuse a community framework to integrate with service providers like Facebook and Twitter"
  category:    CakePHP
  tags:
    - authentication
    - CakeAdvent-2013
    - cakephp
    - oauth
  comments:    true
  sharing:     true
  published:   true
  layout:      post
  series:      CakeAdvent-2013
---

Handling integration with social services is usually something we have to deal with on a case-by-case basis. Most use some flavor of OAuth, at some random level of the spec with their own customizations. Rather than doing this on a one-off basis, it's best we use a package that handles all the vagaries and gives us a single, unified api to authenticate users for social services.

## Opauth

Opauth is a multi-provider authentication framework for PHP. It can integrate with multiple frameworks, one of which is our beloved CakePHP. Let's install it with Composer:

```javascript
"uzyn/cakephp-opauth": "dev-composer"
```

Once it's in our `composer.json`, install it via `composer update`. Next you'll need to load it in your bootstrap.php. It should go after any existing `CakePlugin::loadAll()` call, simply because we'll need to load bootstrap and route code as well:

```php
<?php
// Ensure you are autoloading composer packages!
if (!include (ROOT . DS . 'vendor' . DS . 'autoload.php')) {
  trigger_error("Unable to load composer autoloader.", E_USER_ERROR);
  exit(1);
}

CakePlugin::load('Opauth', array(
  'routes' => true,
  'bootstrap' => true
));
?>
```

Next, you'll want to add in the validation route. This is an app-specific controller/action that is redirected to with valid user data. You can use this to save the record in association with a user. Place the following in your `app/Config/routes.php`:

```php
<?php
Router::connect(
   '/opauth-complete/*',
   array('controller' => 'users', 'action' => 'opauth_complete')
);
?>
```

And you'll want to setup the Controller/action:


```php
<?php
class UsersController extends AppController {
  public function opauth_complete() {
    debug(json_encode($this->data, JSON_PRETTY_PRINT));die.
  }
}
?>
```

### Authentication Strategies

Once we have setup the plugin, we will need to install some authentications strategies. These are used to enable the integration between your site and, for example, Facebook. Let's use Github for this example. Install the strategy in your `composer.json`:

```javascript
"opauth/github": "0.1.0"
```

And run `composer update`. Next, we'll need to configure the strategy in our `bootstrap.php`. After you've loaded the `Opauth` plugin, place the following:

```php
<?php
Configure::write('Opauth.Strategy.GitHub', array(
   'client_id' => 'YOUR GITHUB APP ID',
   'client_secret' => 'YOUR GITHUB APP SECRET'
));
?>
```

At this point, nothing will work because we have not yet created a github application. We can do that in the [Github UI](https://github.com/settings/applications/new). Your callback url will be something like `http://example.com/auth/github/oauth2callback`, where `example.com` is what you replace with your domain name.

You can configure other strategies as necessary, and they will be mounted at `example.com/auth/STRATEGY_NAME`. More strategies are available at the [Opauth readme](https://github.com/opauth/opauth#available-strategies).

### Checking on authentication responses

At this point, you should visit `http://example.com/auth/github`. You will be redirected to Github, where it will ask for your authorization to use the application. Confirm and you'll be redirected to a page with the following JSON output:

```javascript
{
    "auth": {
        "uid": 65675,
        "info": {
            "name": "Jose Diaz-Gonzalez",
            "urls": {
                "blog": "http://josediazgonzalez.com",
                "github": "https://github.com/josegonzalez",
                "github_api": "https://api.github.com/users/josegonzalez"
            },
            "image": "https://2.gravatar.com/avatar/b069294dc48acd6c4cfe8b98fc467c89?d=https%3A%2F%2Fidenticons.github.com%2F454a7bfd685393329597fdb7a92b7969.png&r=x",
            "description": "CakePHP Developer, have worked on small and large projects and specialize in custom CMS development and API Integration.\r\n\r\nI am also interested in the latest Search and Project Management tools, which was my primary research at Sun Microsystems.",
            "nickname": "josegonzalez",
            "email": "MY_EMAIL",
            "location": "New York, NY"
        },
        "credentials": {
            "token": "SOME_TOKEN"
        },
        "raw": {
          "...MORE DATA..."
        },
        "provider": "GitHub"
    },
    "timestamp": "2013-12-09T07:27:34+00:00",
    "signature": "SOME_SIGNATURE",
    "validated": true
}
```

We can use this to save a new user. The following is actual production code I use on a site that handles lunch orders I built for a company hackathon:

```php
<?php
class UsersController extends AppController {
  public function opauth_complete() {
    try {
      $user = $this->User->createOrUpdate($this->request->data);
      $this->Auth->login($user->toLoginArray());

      $this->Session->success(__("%s, you have successfully logged in", $user->first_name));
      return $this->redirect(array('action' => 'dashboard'));
    } catch (Exception $e) {
      $this->Session->danger($e->getMessage());
      return $this->redirect(array('action' => 'oauth_failed'));
    }
  }
?>
```

And the User Model:

```php
<?php
App::uses('EntityModel', 'Entity.Model');
App::uses('UserEntity', 'Model/Entity');

class User extends EntityModel {
  public $entity = true;

  public function createOrUpdate($data) {
    if (empty($data['auth']['credentials']['token'])) {
      throw new Exception('Missing oauth token');
    }

    if (empty($data['validated'])) {
      throw new Exception('Invalid oauth login');
    }

    $user = $this->find('first', array(
      'conditions' => array(
        'Authorization.user_id' => $data['auth']['uid'],
        'Authorization.provider' => $data['auth']['provider'],
      ),
      'contain' => array('Authorization'),
    ));

    if (!$user) {
      $user = $this->entity();
    }

    // Method that ensures we have the attached authorization
    $user->updateFromLogin($data);
    $user->save();

    return $user;
  }
}
?>
```

## Closing Thoughts

Integrating OAuth sign-on with your website doesn't have to be scary, but you should definitely invest time in investigating how to do it right. Opauth can save you a lot of time, but be sure to look into how exactly you want to model your data :)
