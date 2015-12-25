---
  title:       "Designing a Store application in CakePHP"
  date:        2014-12-10 17:24
  description: "Part 1 of 7 in a series of posts designed to teach you how to use CakePHP 3 effectively"
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

This CakeAdvent 2014 tutorial will walk you through the creation of a simple ecommerce store application using CakePHP 3. To start with, we’ll be setting up our development environment, installing our app template, creating our database, and using the tools CakePHP provides to get our application up fast.

---

Lets start by cloning the [FriendsOfCake/vagrant-chef](https://github.com/friendsofcake/vagrant-chef) repository. This repository will provide a full-featured cakephp working environment within a virtual linux server, allowing us to use each and every feature our app will need without worrying about how to install software on our machines.

Assuming you already installed Git, Vagrant and Virtualbox, you can simply clone the `FriendsOfCake/vagrant-chef` repo and start the virtual machine. This should take around 5 minutes on a decent DSL connection, and need only be done once.:

```shell
git clone git@github.com:FriendsOfCake/vagrant-chef.git store
cd store

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

In our last app, we generated migrations by hand and did some mangling of the db. We'll skip that and use an alpha version of the migrations plugin. Install it using the following command:

```shell
cd /vagrant/app

composer require cakephp/migrations:dev-migration-generation
```

> We'll eventually need to use at least dev-master. For now, the functionality we need is in a pull request.

At this point both phinx and the plugin will be installed. Plugins in CakePHP must be enabled before they can be used, and the CakePHP/migrations plugin is no different. Since it's only useful on the command-line, we'll enable it with the following code on our `app/config/bootstrap_cli.php`:

```php
<?php
use Cake\Core\Plugin;

Plugin::load('Migrations');
?>
```

Now we need to create our store's tables:

```shell
cd /vagrant/app

# when creating new tables, you should follow the following format for creating a migration
# - bin/cake bake migration [create_TABLE_NAME] <fields> <go> <here>
#
# reference fields with the following format:
# - field:fieldType:indexType:indexName
bin/cake bake migration create_users email:string:index password:string created modified
bin/cake bake migration create_categories name:string:index created modified
bin/cake bake migration create_order_items order_id:integer product_id:integer quantity:integer price:float created modified
bin/cake bake migration create_orders user_id:integer created modified
bin/cake bake migration create_products name:string stock:integer price:float category_id:integer created modified
```

> When creating new tables, Phinx will automatically add the `id` field, so we don't need to specify it. As well, the migrations plugin is smart enough to auto-assign types to certain fields.

Now you can run your migrations

```shell
cd /vagrant/app

bin/cake migrations migrate
```

Finally, we can bake all the initial files necessary for our application:

```shell
cd /vagrant/app

bin/cake bake all users
bin/cake bake all categories
bin/cake bake all order_items
bin/cake bake all orders
bin/cake bake all products
```

Finally, lets show the `/products` view by default when browsing our site. Modify your `app/config/routes.php` to have the following contents:

```php
<?php
use Cake\Core\Plugin;
use Cake\Routing\Router;

Router::scope('/', function ($routes) {
  $routes->connect('/', ['controller' => 'Products', 'action' => 'index']);

  $routes->fallbacks();
});
?>
```

Now if you browse to http://192.168.13.37/, you'll see our default `products` index page!

---

The above went by really quickly, and while it's still early, our application looks pretty good already. We have a working development environment with any datastore we need, a scaffolded app via the excellent Composer package, run database migrations all from the command-line been introduced to the Bake Shell, and learned a little about customizing our routes. What's next?

- Setting up authentication
- Seeding our store with reasonable information
- Managing our order for specific users
- Add payment processing
- Much moar

We'll cover those over the next few installment of CakeAdvent 2014. Be sure to follow along via twitter on [@savant](https://twitter.com/savant). If you'd like to subscribe to this blog, you may follow the [rss feed here](/atom.xml). Also, all posts in the series will be conveniently linked on the sidebar of every post in the 2014 CakeAdvent Calendar. Come back tomorrow for more delicious content.
