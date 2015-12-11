---
  title:       "Faster Database Creation with the Migrations Plugin"
  date:        2015-12-10 12:00
  description: "Silly hacks you can use in your cakephp applications"
  category:    cakephp
  tags:
    - cakeadvent-2015
    - cakephp
    - table
    - migrations
  comments:    true
  sharing:     true
  published:   true
  layout:      post
  series:      CakeAdvent-2015
---

> I posted about this last year, but since it has landed in the official plugin, I figured I may as well cover it again :)

For developers coming from other RAD frameworks such as Ruby on Rails, you may be familiar with the ability to create table migrations. In the past, there were multiple migration plugins for CakePHP, and as of the 3.0 release, we finally have an official [cakephp/migrations](https://github.com/cakephp/migrations) plugin. Huge shoutout to [Yves Pikel](http://www.havokinspiration.fr/en/) ([@HavokInspiration](https://github.com/HavokInspiration)) for pushing the plugin forward.

Here is a simple migration class:

```php
<?php
use Phinx\Migration\AbstractMigration;

class CreatePosts extends AbstractMigration
{
    public function change()
    {
        $table = $this->table('posts');
        $table->addColumn('name', 'string', [
            'null' => false,
            'default' => null,
            'limit' => 255,
        ]);
        $table->addColumn('created', 'datetime', [
            'null' => false,
            'default' => null,
        ]);
        $table->addColumn('modified', 'datetime', [
            'null' => false,
            'default' => null,
        ]);
        $table->addIndex(['name'], [
            'unique' => false,
            'name' => 'BY_NAME',
        ]);
        $table->create();
    }
}
?>
```

Raise your hand if you would have wanted to create that from scratch.

![http://cl.ly/3W3O0P0N0M0n](https://s3.amazonaws.com/f.cl.ly/items/0I0Z2K1F3K16121h0l0e/Image%202015-12-10%20at%209.08.00%20PM.jpg)

I thought as much.

With the new plugin, we now have the ability to generate those from the command-line. Here is a short example:

```shell
bin/cake bake migration create_posts name:string created modified
```

A few things:

- `id` fields are autocreated. This is a feature of the [Phinx](https://phinx.org/) project we lean on for developing PHP migrations. One-clap to [Rob Morgan](http://robmorgan.id.au/) for managing this project on behalf of the PHP community at large.
- Certain fields have automatic types set if left null. You can always override them though.
- The classname is the UpperCamelCase inflection of the first argument, and means something different depending upon the name:
  - _create_table_ `/^(Create)(.*)/`: Creates the specified table
  - _drop_table_ `/^(Drop)(.*)/`: Drops the specified table. Ignores specified field arguments.
  - _add_field_ `/^(Add).*(?:To)(.*)/`: Adds fields to the specified table
  - _remove_field_ `/^(Remove).*(?:From)(.*)/`: Removes fields from the specified table
  - _alter_table_ `/^(Alter)(.*)/`: Alters the specified table. The alter_table command can be used as an alias for CreateTable and AddField.

This plugin is an absolute must-use for anything prototyping an application which schema changes. No one wants to write the SQL for them, and that goes double for writing actual schema migration files. I recommend [reading the docs](https://github.com/cakephp/migrations#generating-migrations-from-the-cli) on this excellent feature to learn more.

## BONUS ROUND

I normally deploy my code on platforms such as [Heroku](https://www.heroku.com/) or [Dokku](http://dokku.viewdocs.io/dokku/) where composer commands are automatically run for me. Here is my `scripts` field in my `composer.json`:

```json
"scripts": {
    "compile": [
        "bin/cake migrations migrate",
        "bin/cake migrations migrate --plugin Blog"
    ],
    "post-install-cmd": "App\\Console\\Installer::postInstall",
    "post-autoload-dump": "Cake\\Composer\\Installer\\PluginInstaller::postAutoloadDump"
},
```

Other than the normal stuff in there for application installation, you'll notice I have a `scripts.compile` key which maps to a list of migration commands to run. I run the migrations for my core application as well as the blog plugin I use in this particular application. Migrations are now fully automatic for this application, and I don't need to worry about going in and manually altering anything!
