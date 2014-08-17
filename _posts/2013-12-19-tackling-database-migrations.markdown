---
  title:       "Tackling database migrations with one neat trick"
  date:        2013-12-19 00:54
  description: "We look at creating a Cakeshell to generate migration files for the CakeDC Migrations plugin"
  category:    CakePHP
  tags:
    - cakephp
    - migrations
  comments:    true
  sharing:     true
  published:   true
  layout:      post
  series:      CakeAdvent
---

Database schema migrations are a tricky topic. Luckily, CakePHP has the excellent [Migrations plugin by CakeDC](https://github.com/CakeDC/migrations), but creating a new migration file is often obtuse. Rather than diffing the schema, or trying to manually create it, lets automate some of the process with a custom Cakeshell

## Setup

First up, we'll install the [Migrations plugin](https://github.com/CakeDC/migrations). Run the following command in your shell to install it via composer:

```bash
composer require cakedc/migrations 2.2.*
```

Next, lets enable it in our `app/Config/bootstrap.php`:

```bash
echo -e "\nApp::import('Vendor', array('file' => 'autoload'));" >> app/Config/bootstrap.php;
echo -e "\nCakePlugin::loadAll();" >> app/Config/bootstrap.php;
```

Now that it is enabled, we will setup the initial database migrations needed for the plugin itself:

```bash
app/Console/cake Migrations.migration run all -p Migrations
```

## CLI Migration creation

> tl;dr Skip this section and copy the contents of [this gist](https://gist.github.com/josegonzalez/e800ea3a7cc3db3ca56a) to app/Console/Command/MigrationGeneratorShell.php.

At the moment, there is no way to create migrations directly from the command line. Let's build a way to do so!

Create a file in the path `app/Console/Command/MigrationGeneratorShell.php` with the following content:

```php
<?php
App::uses('AppShell', 'Console/Command');
class MigrationGeneratorShell extends AppShell {
?>
```

There isn't much here. We'll want the following interface to the shell:

```bash
# creates a migration that adds a user_id to the testers table
app/Console/cake migration_generator create add_user_id_to_tester user_id:integer:index
```

So we need to add a few methods:

```php
<?php
  public function create() {
  }

  public function getOptionParser() {
    $parser = parent::getOptionParser();
    return $parser->description(
        'The Migration shell.' .
        '')
      ->addSubcommand('Create', array(
        'help' => __('Create a migration file.')));
  }
?>
```

We're going to support the following methods:

- add fields to a table
- remove fields from a table
- create a join table
- create a table
- drop a table

So we'll add the following content to our `create()` function:

```php
<?php
  public function create() {
    $fileName = array_shift($this->args);
    if (preg_match('/^(add|remove)_.*_(?:to|from)_(.*)/', $fileName, $matches)) {
      $method = '_' . $matches[1] . 'Fields';
      $tables = Inflector::tableize(Inflector::pluralize($matches[2]));
    } elseif (preg_match('/^(join)_(.*)_(?:with)_(.*)/', $fileName, $matches)) {
      $method = '_createJoinTable';
      $tables = array($matches[2], $matches[3]);
    } elseif (preg_match('/^(create)_(.*)/', $fileName, $matches)) {
      $method = '_createTable';
      $tables = Inflector::tableize(Inflector::pluralize($matches[2]));
    } elseif (preg_match('/^(remove)_(.*)/', $fileName, $matches)) {
      $method = '_dropTable';
      $tables = Inflector::tableize(Inflector::pluralize($matches[2]));
    }
  }
?>
```

Now that we know what methods we're going to support, and what tables they will apply to, we need some field parsing magic. Below is a semi-intelligent way of getting specified fields, according to our cli schema of `fieldName:type:indexType`:

```php
<?php
  protected function _getFields() {
    $fields = array();
    $indexes = array();
    foreach ($this->args as $field) {
      if (preg_match('/^(\w*)(?::(\w*))?(?::(\w*))?/', $field, $matches)) {
        $fields[$matches[1]] = array(
          'type' => 'string',
          'null' => false,
          'default' => null,
          'key' => null,
        );

        if (empty($matches[2])) {
          $fields[$matches[1]]['type'] = $matches[2];
        }
        if (empty($matches[3])) {
          $fields[$matches[1]]['key'] = $matches[3];
        }

        if (!in_array($fields[$matches[1]]['type'], $this->_validTypes)) {
          switch ($matches[1]) {
            case 'id':
              $fields[$matches[1]]['type'] = 'integer';
              break;
            case 'created':
            case 'modified':
            case 'updated':
              $fields[$matches[1]]['type'] = 'datetime';
              break;
            default:
              $fields[$matches[1]]['type'] = 'string';
          }
        }

        switch ($fields[$matches[1]]['type']) {
          case 'primary_key':
            $indexes['PRIMARY'] = array('column' => $matches[1], 'unique' => 1);
            $fields[$matches[1]]['key'] = 'primary';
          case 'string':
            $fields[$matches[1]]['length'] = 255;
            break;
          case 'integer':
            $fields[$matches[1]]['length'] = 11;
            break;
          case 'biginteger':
            $fields[$matches[1]]['length'] = 20;
            break;
          default:
            break;
        }
      }
    }

    if (!empty($indexes)) {
      $fields['indexes'] = $indexes;
    }
    return $fields;
  }
?>
```

Now lets add the logic for how retrieved fields act within the migration file itself. Note that because we are having a very quick pass at this, both `up` and `down` schema migrations will not be implemented in all cases. Certainly there are ways to improve this as well!

```php
<?php
  protected function _createTable($table) {
    $fields = $this->_getFields();
    return array(
      'up' => array('create_table' => array($table => $fields)),
      'down' => array('drop_table' => array($table)),
    );
  }

  protected function _dropTable($table) {
    $this->out('The `down` step must be manually created');
    return array(
      'up' => array('drop_table' => array($table)),
      'down' => array('create_table' => array()),
    );
  }

  protected function _createJoinTable($tables) {
    $fields = $this->_getFields();
    sort($tables);

    $defaults = array(
      'type' => 'integer',
      'null' => false,
      'default' => null,
      'key' => null,
    );
    foreach ($tables as $i => $table) {
      $tableName = Inflector::tableize(Inflector::pluralize($table));
      $fieldName = Inflector::underscore(Inflector::singularize($tableName)) . '_id';
      $tables[$i] = $tableName;
      if (isset($fields[$fieldName])) {
        $fields[$fieldName] = array_merge($defaults, $fields[$fieldName]);
      } else {
        $fields[$fieldName] = $defaults;
      }
    }

    $joinTable = implode('_', $tables);
    return array(
      'up' => array('create_table' => array($joinTable => $fields)),
      'down' => array('drop_table' => array($joinTable)),
    );
  }

  protected function _addFields($table) {
    $fields = $this->_getFields();
    return array(
      'up' => array('create_field' => array($table => $fields)),
      'down' => array('drop_field' => array($table => array_keys($fields))),
    );
  }

  protected function _removeFields($table) {
    $this->out('The `down` step must be manually created');
    $fields = $this->_getFields();
    return array(
      'up' => array('drop_field' => array($table => array_keys($fields))),
      'down' => array('create_field' => array()),
    );
  }

?>
```

And now for the glue to create the file. We need a single method to create the file contents. Note that you'll need to copy the `migration.ctp` from the migrations plugin into `app/Console/Templates/migration.ctp` for this to work:

```php
<?php
/**
 * Include and generate a template string based on a template file
 *
 * @param string $template Template file name
 * @param array $vars List of variables to be used on tempalte
 * @return string
 */
  private function __generateTemplate($template, $vars) {
    extract($vars);
    ob_start();
    ob_implicit_flush(0);
    include (dirname(__FILE__) . DS . 'Templates' . DS . $template . '.ctp');
    $content = ob_get_clean();

    return $content;
  }
?>
```

Add the following to the end of your `create` method:

```php
<?php
    $class = Inflector::classify($fileName);
    $migration = $this->$method($tables);
    $content = var_export($migration);
    $this->path = APP . 'Config' . DS . 'Migration' . DS;

    $version = gmdate('U');
    $content = $this->__generateTemplate('migration', array('name' => $class, 'class' => $class, 'migration' => $content));
    $path = $this->path . $version . '_' . strtolower($fileName) . '.php';
    $File = new File($path, true);
    $this->out('File created at ' . $path);
    return $File->write($content);
?>
```

## Create a schema file

```bash
app/Console/cake migration_generator create create_users id:primary_key name:string created:datetime modified:datetime
```

Success! You should have a new file in `app/Config/Migration` with your migrations in it. Now you can run them:

```bash
app/Console/cake Migrations.migration run all
```

## More notes

The [CakeDC Migrations readme](https://github.com/CakeDC/migrations) is pretty comprehensive in terms of what it supports. I personally like using `app/Console/cake Migrations.migration status` to check on the status of my migrations in production.

You should definitely look into using [migration callbacks](https://github.com/CakeDC/migrations#callbacks). Callbacks are a simple way of populating your production database with relevant information before or after a database migration. For instance, if you are creating a new name field that combines all the users names, you might want to run an update statement in the `afterMigration` callback to populate that field for all existing users.

I've hooked up migrations into the deploy process of most of my applications. It's pretty trivial to run migrations automatically - just do `run all` - and there is no reason to not do so after an application deployment.
