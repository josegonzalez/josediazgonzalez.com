---
  title:       "Deploying a CakePHP application to Heroku"
  date:        2013-12-22 15:18
  description: "Heroku is a popular place to try out small experiments in CakePHP, so I decided to document the steps necessary for a successful Heroku integration."
  category:    CakePHP
  tags:
    - cakeadvent-2013
    - cakephp
    - heroku
  comments:    true
  sharing:     true
  published:   true
  layout:      post
  series:      CakeAdvent-2013
---

These are some notes from my deploy of an application I am developing to Heroku. There are some specialized things you need to do to make everything work, so hopefully I catch everything.

## Use FriendsOfCake/app-template

The biggest bit here is to ensure that we are properly using composer for everything but our application logic. Most people tend to bundle the CakePHP core with their app in version control, but we can safely rely on Composer to be run before the application is deployed. Having CakePHP installed via composer allows us to safely and quickly test upgrades from one release to another.

```shell
composer -sdev create-project friendsofcake/app-template your_app
```

### Add a root `index.php`

We'll need it to make the CakePHP app compatible with the buildpack we'll be using:

```php
<?php
define('APP_DIR', 'app');
define('DS', DIRECTORY_SEPARATOR);
define('ROOT', dirname(__FILE__));
define('WEBROOT_DIR', 'webroot');
define('WWW_ROOT', ROOT . DS . APP_DIR . DS . WEBROOT_DIR . DS);

require APP_DIR . DS . WEBROOT_DIR . DS . 'index.php';
?>
```

## Use environment variables for Configuration

We'll be using Postgres in production - a big change for many CakePHP developers - because it's what much of the heroku tooling works around. However, we still need to connect to the database, so here is what I have in my application's `database.php`:

```php
<?php
class DATABASE_CONFIG {

  public $default;

  public $test = array(
    'persistent' => false,
    'host' => '',
    'login' => '',
    'password' => '',
    'database' => 'cakephp_test',
    'prefix' => ''
  );

  public function __construct() {
    $DATABASE_URL = parse_url(getenv('DATABASE_URL'));
    $this->default = array(
      'datasource' => 'Database/Postgres',
      'persistent' => false,
      'host'       => $DATABASE_URL['host'],
      'login'      => $DATABASE_URL['user'],
      'password'   => $DATABASE_URL['pass'],
      'database'   => substr($DATABASE_URL['path'], 1),
      'prefix'     => '',
      'encoding'   => 'utf8',
    );
  }

}
?>
```

This does mean you'll need to do extra work to get the app running locally, but it shouldn't be too difficult.

## Use [CHH/heroku-buildpack-php](https://github.com/CHH/heroku-buildpack-php)

This buildpack does a lot of the gruntwork to get a PHP app running to current community standards. Built-in support for Composer, PHP 5.5, PHP-FPM and Nginx. I approve.

```shell
heroku config:set BUILDPACK_URL=https://github.com/CHH/heroku-buildpack-php
```

### Configure a CakePHP app in your `composer.json`

The `CHH/heroku-buildpack-php` uses our `composer.json` to figure out how to serve the application. I add an `extra` key to ensure my app is properly routed.

```javascript
"extra": {
  "heroku": {
    "document-root": "app/webroot",
    "index-document": "index.php"
  }
}
```

## Use Redis or Memcached for Caching

Both of these are available in the buildpack we use. Distributed caching is *much* nicer, especially if your dyno can go to sleep. Here is what I use to parse the DSN:

```php
<?php
$login = null;
$password = null;
$server = null;
$servers = null;

if (extension_loaded('apc') && function_exists('apc_dec') && (php_sapi_name() !== 'cli')) {
  $engine = 'Apc';
}

if (getenv('MEMCACHED_URL')) {
  // Custom Memcached implementation
  include ROOT . DS . APP_DIR . DS . 'Lib' . DS . 'Memcached.php';
  $engine = 'Memcached';
  $MEMCACHED_URL = parse_url(getenv('MEMCACHED_URL'));
  $servers = Hash::get($MEMCACHED_URL, 'host');
  $port = Hash::get($MEMCACHED_URL, 'port');
  $login = Hash::get($MEMCACHED_URL, 'user');
  $password = Hash::get($MEMCACHED_URL, 'pass');
} elseif (getenv('REDIS_URL')) {
  // Custom Redis implementation
  include ROOT . DS . APP_DIR . DS . 'Lib' . DS . 'Redis.php';
  $engine = 'Redis';
  $REDIS_URL = parse_url(getenv('REDIS_URL'));
  $server = Hash::get($REDIS_URL, 'host');
  $port = Hash::get($REDIS_URL, 'port');
  $login = Hash::get($REDIS_URL, 'user');
  $password = Hash::get($REDIS_URL, 'pass');
}

$prefix = 'app_';

// In development mode, caches should expire quickly.
$duration = '+999 days';
if (Configure::read('debug') > 0) {
  $duration = '+10 seconds';
}

// Setup a 'default' cache configuration for use in the application.
Cache::config('default', array(
  'engine' => $engine,
  'prefix' => $prefix . 'default_',
  'path' => CACHE . 'persistent' . DS,
  'serialize' => ($engine === 'File'),
  'duration' => $duration,
  'login' => $login,
  'password' => $password,
  'server' => $server,
  'servers' => $servers,
));
?>
```

## Log to a custom path

Your application will not be able to stream logs to you unless you use a custom logging path. Here is how I configured it in my `bootstrap.php`:

```php
<?php
CakeLog::config('default', array(
    'engine' => 'FileLog',
    'file' => 'stdout.log',
    'path' =>  getenv('LOG_PATH'),
    'types' => array('notice', 'info', 'debug'),
));

CakeLog::config('error', array(
    'engine' => 'FileLog',
    'file' => 'error.log',
    'path' =>  getenv('LOG_PATH'),
    'types' => array('emergency', 'alert', 'critical', 'error', 'warning'),
));
?>
```

And the configuration:

```shell
heroku config:set LOG_PATH=/app/vendor/php/var/log/
```

## Use UTC Date Time

If you're building a new application, do it correctly. In your `core.php`, uncomment the datetime call:

```php
date_default_timezone_set('UTC');
```

## Copy plugin assets into the webroot

Because of our virtualhost configuration, plugins will not have their assets served up properly. Here is what I have in my composer.json (under the `extra` key):

```javascript
"extra": {
  "heroku": {
    "document-root": "app/webroot",
    "index-document": "index.php",
    "compile": [
      "echo 'Copying DebugKit webroot directory' && cp -rfp $BUILD_DIR/Plugin/DebugKit/webroot $BUILD_DIR/app/webroot/debug_kit"
    ]
  }
}
```
