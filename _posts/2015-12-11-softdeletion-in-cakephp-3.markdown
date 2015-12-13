---
  title:       "SoftDeleting Entities in CakePHP 3"
  date:        2015-12-11 12:00
  description: "Silly hacks you can use in your cakephp applications"
  category:    cakephp
  tags:
    - cakeadvent-2015
    - cakephp
    - table
    - softdelete
  comments:    true
  sharing:     true
  published:   true
  layout:      post
  series:      CakeAdvent-2015
---

When creating CMS-like software, it is useful to have "undo" triggers in your application. Sometimes you want to revert to a previous version of a record, or undo a hasty delete. For the latter case, it is often useful to implement some form of a "softdelete" functionality.

## Muffin/Trash

Here is a lovely plugin for 3.x that you can use to implement soft-delete. Let's install it!

```shell
# install using composer
composer require muffin/trash:1.0.0

# require it using the plugin:load shell I just found out about
bin/cake plugin load Muffin/Trash
```

This plugin depends upon us having a `deleted` or `trashed` field in our database table. Lets create a migration for our `posts` table:

```shell
# generate the migration using the migrations plugin
bin/cake bake migration add_deleted_to_posts deleted:datetime

# migrate the table
bin/cake migrations migrate
```

And now we can add the behavior to our Table class:

```php
$this->addBehavior('Muffin/Trash.Trash');
```

We could have also used a custom field like `deleted_at`, but that requires more configuration, and I'm lazy so that's not going to happen.

Next, lets see how we can use this behavior:

```php
$table = $this->loadModel('Posts');
$post = $table->get(1);

// simply marks the entity as in the trash
$table->trash($post);

// this fails because it's already in the trash
$table->trash($post);

// When the behavior is attached, `delete()` is the same as `trash()`
$table->delete($post);

// "recycle's" things from the trash
$table->restoreTrash($post);

// by default, all your trash is excluded
$posts = $table->find()->all();

// but you can find everything, including things in the trash
$posts = $table->find()->withTrashed()->all();
```

If you want to disable the overriding of `delete()` with `trash()`, you can attach the behavior like so:

```php
// Useful if you bake actions for soft-delete and force-delete
$this->addBehavior('Muffin/Trash.Trash', [
    'events' => ['Model.beforeFind']
]);
```

The plugin is already quite useful - in fact, I'm using it in 2 applications already - and can probably take care of 90% of your soft-deletion needs.

