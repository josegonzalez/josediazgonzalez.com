---
  title:       "Application Environment Configuration"
  date:        2013-12-20 13:31
  description: "Specifying application configuration doesn't have to be hard, and here are three ways to do it!"
  category:    CakePHP
  tags:
    - cakeadvent-2013
    - cakephp
    - configuration
  comments:    true
  sharing:     true
  published:   true
  layout:      post
  series:      CakeAdvent-2013
---

Something I see a lot of developers struggle with is handling various environments separate from one other. I'll go over a few methods here, specific to CakePHP applications.

## Switch on hostname

This version is the least likely to work alone. Essentially, you switch configuration based on whatever hostname is requesting your application. For instance, you might configure your cache as follows:

```php
<?php
if (in_array(env('SERVER_NAME'), array('example.com', 'staging.example.com'))) {
  // production
  Cache::config('default', array('engine' => 'Apc'));
} else {
  // staging
  Cache::config('default', array('engine' => 'File'));
}
?>
```

Why won't this work?

- You probably do not have the `SERVER_NAME` environment variable set in CLI mode. If you do specify it, that isn't intuitive and it is likely that someone will forget to specify it at one point or another
- If you add more hostnames - which can and will happen - you have to go back and respecify this everywhere
- This is likely to be sprinkled throughout your application

## Use the Environment Plugin

> This method can be used by using the [Environment Plugin](https://github.com/octobear/cakephp-environments)

Early on in my CakePHP usage, I started using environment files. I would have a different environment file for each configuration:

- `app/Config/bootstrap/environments.php`
- `app/Config/bootstrap/environments/production.php`
- `app/Config/bootstrap/environments/staging.php`
- `app/Config/bootstrap/environments/development.php`

Your `environments.php` file would contain the following:

```php
<?php
CakePlugin::load('Environments');
App::uses('Environment', 'Environments.Lib');

include dirname(__FILE__) . DS . 'environments' . DS . 'production.php';
include dirname(__FILE__) . DS . 'environments' . DS . 'staging.php';
include dirname(__FILE__) . DS . 'environments' . DS . 'development.php';

Environment::start();
?>
```

An example `development.php`:

```php
<?php
Environment::configure('development',
  true, // Defaults to development
  array(
    'Settings.FULL_BASE_URL'  => 'http://example.dev',

    'Email.username'          => 'email@example.com',
    'Email.password'          => 'password',
    'Email.test'              => 'email@example.com',
    'Email.from'              => 'email@example.com',

    'logQueries'              => true,

    'debug'                   => 2,
    'Cache.disable'           => true,
    'Security.salt'           => 'SALT',
    'Security.cipherSeed'     => 'CIPHERSEED',
  ),
  function() {
    if (!defined('FULL_BASE_URL')) {
      define('FULL_BASE_URL', Configure::read('Settings.FULL_BASE_URL'));
    }
  }
);
?>
```

This was great, because now all my configuration was in one place, and all I needed to do was redeploy the app and every configuration would be picked up.

The environment switching was done by the existing of a `CAKE_ENV` environment variable or by hostname, so I could get away with local development pretty easily as well as with command-line tools:

```shell
CAKE_ENV=production app/Console/cake Migrations.migration run all -p Migrations
```

One draw-back to this method is that now we assume that all developers will locally have the same environment. This is likely to be false - if we work on different projects, our database usernames might collide, or perhaps your Windows laptop can use WinCache and mine can use Opcache.

The other big issue is that this exposes production credentials for everything to all developers. While you may trust your developers, the day might come when you have an untrusted user - non-developer, or a new guy, or even a security auditor - that you'd rather not have complete access to your system, and thus it's preferable to avoid specifying production environment information within the repository.

## Environment Variable all the things

This is my current favorite. Essentially, all configuration is retrieved from an environment variable. You would, for instance, retrieve cache configuration from the `CACHE_URL` environment variable:

```shell
CACHE_URL=redis://localhost:6379/0 app/Console/cake Migrations.migration run all -p Migrations
```

Your CakePHP code would parse environment variables as necessary to retrieve the data and configure your app.

Some benefits:

- Easily swap between one config and another.
- No need to force one user to use a configuration in their environment
- Can be used across multiple frameworks and languages, not just CakePHP

However, it's more annoying to specify multiple config values:

```shell
export CACHE_URL=redis://localhost:6379/0
export DATABASE_URL=mysql://localhost:3306/example
export TEMP_PATH=/mnt
app/Console/cake Migrations.migration run all -p Migrations
```

I normally create a file in `/etc/services/my-service` with the exports:

```shell
export CACHE_URL=redis://localhost:6379/0
export DATABASE_URL=mysql://localhost:3306/example
export TEMP_PATH=/mnt
```

And then source the file in:

```shell
. /etc/services/my-service app/Console/cake Migrations.migration run all -p Migrations
```
