---
  title:       "Adding dummy data via a custom faker shell to our store"
  date:        2014-12-12 18:26
  description: "Part 3 of 7 in a series of posts designed to teach you how to use CakePHP 3 effectively"
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

The excellent [Jad Bittar](http://jadb.io) added support for Faker to the Cake3 ORM as a plugin, so we can use this to generate dummy data for our application. This will allow us to easily test stuff going forward. Let's start by installing the plugin:

```shell
composer require gourmet/faker
```

This will pull in both the CakePHP plugin as well as the Faker library. Next, lets generate a shell to generate dummy data:

```shell
cd /vagrant/app

# generate a dummy data shell
bin/cake bake shell DummyData
```

The new shell will be created in `app/src/Shell/DummyDataShell.php`. It has a `main` method which you can modify, and if you run the following command now:

```shell
bin/cake dummy_data
```

You'll have the following - pretty plain - output:

```
vagrant@precise32:/vagrant/app$ bin/cake dummy_data

Welcome to CakePHP v3.0.0-beta3 Console
---------------------------------------------------------------
App : src
Path: /vagrant/app/src/
---------------------------------------------------------------
```

Lets actually do something with this new shell. In our `DummyDataShell::main()` method, we'll need to create a `faker` object

```php
$faker = \Faker\Factory::create();
```

Faker uses providers to give custom data types to fields. We'll first populate the `users` table, and to do so, we'll need to provide fake email addresses. To do so, we'll need to add the `Internet` provider:

```php
$faker->addProvider(new \Faker\Provider\Internet($faker));
```

To populate a specific type of entity, we need to create an EntityPopulator object. The Faker library provides a custom populator for the CakePHP framework, which we'll leverage in our case. You simply need to provide the name of the table class:

```php
$entityPopulator = new \Faker\ORM\CakePHP\EntityPopulator('Users');
```

Finally, we need to create a populator object that will actually insert data into the database. We need to pass in our EntityPopulator object, a number of records to insert, as well as custom formatters. The formatters come from providers - we added the `Internet` provider above - or your own text. Faker tries to autodetect data types, but will default to stuff like `plaintext` for `email` fields, so we need to override this:

```php
$populator = new \Faker\ORM\CakePHP\Populator($faker);
$populator->addEntity($entityPopulator, 20, [
  'email' => function () use ($faker) { return $faker->email(); },
  'password' => 'password',
]);
```

The last thing is to actually populate our table!

```php
$populator->execute(['validate' => false]);
```

The full code sample will look like the following:

```php
$this->out("Creating user populator");
$faker = \Faker\Factory::create();
$faker->addProvider(new \Faker\Provider\Internet($faker));

$entityPopulator = new \Faker\ORM\CakePHP\EntityPopulator('Users');
$populator = new \Faker\ORM\CakePHP\Populator($faker);
$populator->addEntity($entityPopulator, 20, [
  'email' => function () use ($faker) { return $faker->email(); },
  'password' => 'password',
]);

$this->out("Inserting");
$populator->execute(['validate' => false]);
```

> I've added some calls to `$this->out()` to provide feedback in my shell. You can omit these or add more as you like. This is a special helper method available in shells

If you run this, you'll recieve the following output:

```
vagrant@precise32:/vagrant/app$ bin/cake dummy_data

Welcome to CakePHP v3.0.0-beta3 Console
---------------------------------------------------------------
App : src
Path: /vagrant/app/src/
---------------------------------------------------------------
Creating user populator
Inserting
```

But more importantly, you'll have 20 beautiful user records with passwords. You should be able to login as any of these users.

## Homework time!

If you thought you'd get off this week, you thought incorrectly. Your homework is to create dummy data for every model we have in our app - a store without products is kind of useless. You can ignore the `Orders` and `OrderItems` models.
