---
  title:       "Composing your applications from plugins"
  date:        2013-12-08 06:15
  description: "Properly manage your CakePHP application dependencies using Composer, a PHP dependency management tool"
  category:    CakePHP
  tags:
    - cakephp
    - composer
    - dependency management
  comments:    true
  sharing:     true
  published:   true
  layout:      post
  series:      CakeAdvent
---

In previous CakeAdvent posts, I've been speaking about using a tool called [Composer](http://getcomposer.org/). Composer is a PHP dependency management tool, not unlike [Bundler for Ruby](http://bundler.io/) or [Pip for Python](http://www.pip-installer.org/en/latest/). We can use it to manage the installation and maintenance of third-party components in our application.

## Composer installation

> Composer requires PHP 5.3, and this tutorial will require PHP 5.4. You really should upgrade, considering 5.3 is EOL and 5.5 is currently stable.

For the rest of this post, you'll need the composer tool installed. The following are instructions across various systems to do so:

### Mac OS X

Users of the homebrew package manager can use the `homebrew-php` tap to install composer globally, which is the easiest way of interacting with the tool:

```bash
brew tap josegonzalez/php
brew install composer
```

### Manual Install

The following will manually install the `composer.phar` in your current directory. Note that you'll need to execute a PHP script from the internet, so be mindful of not running as root or verifying the script contents:

```bash
curl -sS https://getcomposer.org/installer | php
```

If you wish to make it globally available, please install it to your `/usr/local/bin` directory:

```bash
curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin
```

I normally rename the `composer.phar` file to remove the extension:

```bash
mv composer.phar composer
```

Other manual instructions are available on the [composer website](http://getcomposer.org/download/)

## Application Skeletons

The first thing most people get stuck on is how to manage your application distinctly from the CakePHP core. This is a bit weird, because in the 1.x and 2.x line, the CakePHP framework is distributed with an `app` folder. Instead, your app folder should be the base of the repository. Let's start from scratch and see what this might look like.

Composer has the ability to create projects from project templates registered on the official composer repository, [Packagist.org](https://packagist.org/). In our case, the [FriendsOfCake](http://friendsofcake.com/) organization provides a composer template for CakePHP application development. We'll use it to create a new app called `lollipop`:

```bash
composer -sdev create-project friendsofcake/app-template lollipop
```

![http://cl.ly/image/2c0E353d0V0k](http://cl.ly/image/2c0E353d0V0k/Screen%20Shot%202013-12-08%20at%2010.14.30%20AM.png)

> The command in the image is purposefully different from what is written.

What the above command does is create a new project named `lollipop` based on `friendsofcake/app-template` project. It will use the stability minimum of `dev` for all dependencies. You can change it to something else if desired.

You'll want to point your virtualhost root to the `app/webroot` directory. Beginning CakePHP developers usually point to the directory containing `app` and `lib`, but this is both incorrect and a potential security hazard. The purpose of this project template is to foster good practices, so keep this in mind.

Some things you'll want to update:

- Use a caching engine other than `Apc`. By default, it is set to `File`.
- Set the default timezone in PHP to `UTC` via `date_default_timezone_set('UTC');`. UTC should be standard across your infrastructure for reasons outside the scope of this post.
- Create a `database.php` with your db credentials.
- Update `Security.cipherSeed` and `Security.salt` in your `core.php`

## Dependencies

### Plugins

By default, this application template comes with the following plugins:

- Crud: An application scaffolding tool
- DebugKit: A toolbar used to add debug information to your application

These are maintained within the `composer.json` file. Lets add the CakeEntity plugin to this file, under the `require` block:

```javascript
"josegonzalez/cakephp-entity": "1.0.0"
```

And then install the plugin:

```bash
composer update
```

We should now have the directory `./Plugin/Entity` available to us!

### PHP Packages

Composer can be used to handle non-cakephp dependencies as well. For example, lets say we wanted to install the `Identicon` dependency from CakeAdvent Day 2. We would add the following to our `require` block:

```javascript
"yzalis/identicon": "*"
```

And simply run `composer update` to install the package. This time, you'll need to find the `identicon` package within `./vendor/yzalis/identicon`. Composer will automatically handle placing CakePHP plugin vs all else within the appropriate directories.

To require non-cakephp code within your application, you will want to require the proper `autoload` file. For example, in our `boris` shell, we might want to use following instead of the existing boris autoloader:

```php
<?php
if (!include (ROOT . DS . 'vendor' . DS . 'autoload.php')) {
  trigger_error("Unable to load composer autoloader.", E_USER_ERROR);
  exit(1);
}
?>
```

We could implement similar code within our application's `bootstrap.php`. This removes the need to manually require non-CakePHP code, keeping your include structure relatively easy to understand.

## Composer: A step in the right direction

CakePHP 3.0 fully embraces composer right down to the core. While we are able to use Composer with 2.x applications - and 1.x to a certain extent - you should expect all CakePHP code to conform to composer specifications going forward.

Managing your application dependencies *today* should be much easier due to composer. Feel free to browse for other packages on [Packagist.org](https://packagist.org/)
