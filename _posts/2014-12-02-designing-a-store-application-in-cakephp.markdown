---
  title:       "Designing an anonymous issue tracker in CakePHP"
  date:        2014-12-02 16:22
  description: "Part 1 of 7 in a series of posts designed to teach you how to use CakePHP 3 effectively"
  category:    CakePHP
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

This CakeAdvent 2014 tutorial will walk you through the creation of a simple anonymous issue tracking application using CakePHP 3. To start with, we’ll be setting up our development environment, installing our app template, creating our database, and using the tools CakePHP provides to get our application up fast.

---

Lets start by cloning the [FriendsOfCake/vagrant-chef](https://github.com/friendsofcake/vagrant-chef) repository. This repository will provide a full-featured cakephp working environment within a virtual linux server, allowing us to use each and every feature our app will need without worrying about how to install software on our machines.

Assuming you already installed Git, Vagrant and Virtualbox, you can simply clone the `FriendsOfCake/vagrant-chef` repo and start the virtual machine. This should take around 5 minutes on a decent DSL connection, and need only be done once.:

```shell
git clone git@github.com:FriendsOfCake/vagrant-chef.git anonymous-issues
cd anonymous-issues

# bring up the working vm
vagrant up
```

Now that the virtualmachine is running, you can ssh onto it. Windows users will need to use [Putty](http://www.chiark.greenend.org.uk/~sgtatham/putty/) or similar, but please refer to the vagrant docs on how to connect.

```shell
# ssh onto the vm
vagrant ssh
```

Now that you are connected to your development environment, you should be able to create an application. `FriendsOfCake/vagrant-chef` currently expects the application to be available in it's `app` directory, so we'll keep that in mind.

As of CakePHP 3, we create new applications using the [Composer](https://getcomposer.org/) `create-project` command:

```shell
composer create-project --prefer-dist -s dev cakephp/app app
```

Running the above will have output similar to the following:

```
Installing cakephp/app (dev-master 28008873514274db441338eff5e2d07e75274f48)
  - Installing cakephp/app (dev-master master)
    Downloading: 100%

Created project in app
Loading composer repositories with package information
Installing dependencies (including require-dev)
  - Installing cakephp/plugin-installer (0.0.1)
    Downloading: 100%

  - Installing aura/installer-default (1.0.0)
    Downloading: 100%

  - Installing nesbot/carbon (1.13.0)
    Downloading: 100%

  - Installing psr/log (1.0.0)
    Downloading: 100%

  - Installing aura/intl (1.1.1)
    Downloading: 100%

  - Installing ircmaxell/password-compat (v1.0.4)
    Downloading: 100%

  - Installing cakephp/cakephp (3.0.x-dev 360c04e)
    Downloading: 100%

  - Installing cakephp/debug_kit (3.0.x-dev 8a6f3da)
    Downloading: 100%

  - Installing mobiledetect/mobiledetectlib (2.8.11)
    Downloading: 100%

  - Installing d11wtq/boris (v1.0.8)
    Downloading: 100%

Writing lock file
Generating autoload files
Created `config/app.php` file
Permissions set on /vagrant/app/tmp/cache
Permissions set on /vagrant/app/tmp/cache/models
Permissions set on /vagrant/app/tmp/cache/persistent
Permissions set on /vagrant/app/tmp/cache/views
Permissions set on /vagrant/app/tmp/sessions
Permissions set on /vagrant/app/tmp/tests
Permissions set on /vagrant/app/tmp
Permissions set on /vagrant/app/logs
Updated Security.salt value in config/app.php
```

In previous versions of cake, you would need to configure your security salt and change permissions, though we now take care of this for you automatically. You'll still need to change your database permissions in your `app/config/app.php` file. `FriendsOfCake/vagrant-chef` comes preinstalled with many datastores, so we'll use MySQL for this sample application. The following are the credentials you will need to change in your `app/config/app.php`:

- username: `root`
- password: `bananas`
- database: `database_name`

Now that we've setup our database, we can import an initial schema into our app. There is currently no automated way to create a schema - though it's coming quite soon - so we'll connect to MySQL:

```shell
mysql -uroot -pbananas
# run the following command within the mysql connection
use database_name;
```

And import the following:

```sql
CREATE TABLE `comments` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `issue_id` int(11) DEFAULT NULL,
  `email_address` varchar(255) DEFAULT NULL,
  `comment` text,
  `created` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `issues` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `title` varchar(255) DEFAULT NULL,
  `text` text,
  `created` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
```

Disconnecting from the mysql terminal will drop us back into our linux virtualmachine, where we can now generate some general application scaffolding using the Bake utility. `Bake` is a CakePHP command-line utility that allows us to template out various types of files. We could, for instance, template out custom migration files if we installed the Migrations plugin. In our case, we're going to use it to generate Controllers, Table classes, Entities, and Template files for our `issues` table. This allows us to skip a lot of the boring work of creating various files that won't vary much from application to application.

```shell
cd /vagrant/app
bin/cake bake all issues
```

If you browse to http://192.168.13.37/issues, you'll see your baked app in action. If you browse to http://192.168.13.37/, you'll see that we have the generic CakePHP 3 landing page. Rather than show this to our users, lets show them the issues page by default.

CakePHP 3's routing layer - which is specified in the `app/config/routes.php` file - uses scoped routes. This means that you can do stuff like:

```php
<?php
Router::scope('/blog', ['plugin' => 'Blog'], function ($routes) {
    $routes->connect('/', ['controller' => 'Articles']);
});
?>
```

In our case, we're going to use the default scope and change the routes.php file to the following:

```php
<?php
use Cake\Core\Plugin;
use Cake\Routing\Router;

Router::scope('/', function ($routes) {
  $routes->connect('/', ['controller' => 'Issues', 'action' => 'index']);

  $routes->fallbacks();
});
?>
```

A few notes:

- We removed the `/pages/*` catch-all route. This isn't necessary unless you have static pages, which our app will not.
- We also removed plugin routing. This decreases the time it takes for the router class to process all the routes, though will break routing for any plugins. We can always add it back in the future.

Now if you browse to http://192.168.13.37/, you'll see our default `issues` index page!

---

The above went by really quickly, and while it's still early, our application looks pretty good already. We have a working development environment with any datastore we need, a scaffolded app via the excellent Composer package, been introduced to the Bake Shell, and learned a little about customizing our routes. What's next?

- Customizing our bake templates to make baking faster in the future
- Generating Schema migrations from the command-line
- Attaching comments to issues and associating them automatically

We'll cover those in the next installment of CakeAdvent 2014. Be sure to follow along as via twitter on [@savant](https://twitter.com/savant). If you'd like to subscribe to this blog, you may follow the [rss feed here](http://josediazgonzalez.com/atom.xml). Also, all posts in the series will be conveniently linked on the sidebar of every post in the 2014 CakeAdvent Calendar. Come back tomorrow (if you're reading this on the 2nd of December!) for more delicious content.
