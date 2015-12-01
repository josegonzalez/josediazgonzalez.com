---
  title:       "Schema Migrations with CakePHP 3"
  date:        2014-12-04 14:22
  description: "Part 3 of 7 in a series of posts designed to teach you how to use CakePHP 3 effectively"
  category:    cakephp
  tags:
    - cakeadvent-2014
    - cakephp
    - composer
    - migrations
    - phinx
  comments:    true
  sharing:     true
  published:   true
  layout:      post
  series:      CakeAdvent-2014
---

> I corrected a few issues with the previous post regarding the redirect and `requirePost` event. They've been corrected.

In our previous post, I gave you all some homework:

- Make the form actions optional - and turn them off for embedded forms.
- Create a nicer comment list than the current version.
- Hide the `issue_id` field on the form without removing it completely

For the first task, you can extract the form actions into a separate element and make the inclusion of that element conditional - default true - on a variable you specify from the event.

For the second task, using a custom element for related entities is the way to go.

For the third task, you will want to populate a new variable - lets call it `$inputOptions` - and have it be an array of `field` => `options` for the field. Each field being output should be in this array with a default empty array as it's options. You can use the `BakeHelper::stringifyList` to turn those options into a nicely formatted string array.

---

One thing that is a pain is managing database schema changes. While we had [CakeDC/migrations](https://github.com/cakedc/migrations) in the 2.x world, CakePHP 3 is about embracing existing solutions to problems. In CakePHP 3, we've delegated the task to the excellent [Phinx](https://phinx.org/) library. Phinx is a database migration tool that CakePHP provides a wrapper for with the [CakePHP/migrations](https://github.com/cakephp/migrations) plugin. You can use Phinx outside of CakePHP as well, so switching back and forth between CakePHP and other PHP frameworks should be a breeze.

To install the migrations plugin, we'll use composer:


```shell
# ssh onto the vm
vagrant ssh

cd /vagrant/app
composer require cakephp/migrations:dev-master
```

At this point both phinx and the plugin will be installed. Plugins in CakePHP must be enabled before they can be used, and the CakePHP/migrations plugin is no different. Since it's only useful on the command-line, we'll enable it with the following code on our `app/config/bootstrap_cli.php`:

```php
<?php
use Cake\Core\Plugin;

Plugin::load('Migrations');
?>
```

Now that it's enabled, we can generate our initial migration from the existing database:

```shell
cd /vagrant/app
bin/cake bake migration Initial
```

The output should be similar to the following:

```
Welcome to CakePHP v3.0.0-beta3 Console
---------------------------------------------------------------
App : src
Path: /vagrant/app/src/
---------------------------------------------------------------

Baking migration class for Connection default

Creating file /vagrant/app/config/Migrations/20141204225440_initial.php
Wrote `/vagrant/app/config/Migrations/20141204225440_initial.php`
```

If we look at that file, we'll see a phinx-style migration that contains all the information about our current database schema. This can be useful for bootstrapping a new database (though our database works just fine for now). It's pretty similar to the old migrations plugin - you get an `up`, `down`, and `change` method - but uses an object-oriented approach to changing the database.

You can rollback any migration with the `down()` callback by running the following command:

```shell
bin/cake migrations rollback
```

And if you have created new migrations, you can migrate up to them:

```shell
bin/cake migrations migrate
```

One note, there is currently an issue where the Phinx library auto-includes an auto-increment `id` field for every database. This might not be desired for certain tables, in which case you'll want to manually disable the field:

```php
<?php
$table = $this->table('statuses', [
    'id' => false,
    'primary_key' => ['id']
]);
?>
```

For more docs, see the [phinx documentation here](http://docs.phinx.org/en/latest/migrations.html#creating-a-new-migration)

## Homework Time!

This was a relatively short introduction to database migrations, but I felt it important enough to cover as we'll be using them extensively over the next few tutorials. Your homework is actually pretty simple. We need to keep track of a `webhook_url` string field with a length of 256 characters in our `comments` table. Create a new migration and add the field to the table. The command to create an empty migration is as follows:

```shell
bin/cake migrations create WebhookUrl
```

Note, there is a bug in Phinx's - not Cake's! - templates where the end-docblock for the `change()` method is in the wrong place. We'll get that fixed up before CakePHP 3 goes stable :)
