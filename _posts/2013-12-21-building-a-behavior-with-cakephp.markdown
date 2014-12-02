---
  title:       "Building a Behavior with CakePHP"
  date:        2013-12-21 14:52
  description: "Covering the creation of a plugin, writing Unit Tests, and creating a Behavior to handle a `deleted` field"
  category:    CakePHP
  tags:
    - CakeAdvent-2013
    - cakephp
    - behaviors
    - plugins
    - testing
  comments:    true
  sharing:     true
  published:   true
  layout:      post
  series:      CakeAdvent-2013
---

I've been meaning to create a `deleted_at` behavior, and today we'll go over that.

## Creating Plugin Scaffolding

I normally place non-application code in a plugin. Most extensions to your core logic - behaviors, components, helpers - fall into this category. You can normally tell if it is pluginizable if you can imagine reusing the logic within the context of a CMS and an Issue Tracker :)

Lets create the followin directory structure:

```bash
cd path/to/app
mkdir -p app/Plugin/DeletedAt/Model/Behavior
```

Next, we'll initialize our plugin as a git repository. We're doing this with the aim of having the plugin within hosted Packagist:

```bash
cd app/Plugin/DeletedAt
touch Model/Behavior/empty
git init
git add Model/Behavior/empty
git commit -m "Initial commit"
git push origin master
```

> The above assumes you created a repository on github to push your code to. Github is where *most* CakePHP code exists, and it would be beneficial to the community to continue to use a single type of version control+code repository. Obviously, you can and should change this according to your needs.

And now we'll make this a [FriendsOfCake-approved](http://friendsofcake.com/) plugin using the steps from the [first CakeAdvent post](/2013/12/01/testing-your-cakephp-plugins-with-travis/):

```bash
cd path/to/app
git clone git@github.com:FriendsOfCake/travis.git vendor/travis
export COPYRIGHT_YEAR=2013
export GITHUB_USERNAME="josegonzalez"
export PLUGIN_PATH="Plugin/DeletedAt"
export PLUGIN_NAME="DeletedAt"
export REPO_NAME="cakephp-deleted-at"
export YOUR_NAME="Jose Diaz-Gonzalez"
./vendor/travis/setup.sh
rm -rf vendor/travis
cd Plugin/DeletedAt
git add .
git commit -m "FriendsOfCake support"
git push origin master
```

At this point, you should be able to enable support for the plugin within TravisCI, Packagist, and Coveralls.

## Creating a simple Behavior

We'll first need to create the proper files. We will have both a `DeletedAtBehavior.php` and a `DeletedAtBehaviorTest.php`. Lets do that:

```bash
cd app/Plugin/DeletedAt
mkdir -p Test/Case/Model/Behavior
touch Model/Behavior/DeletedAtBehavior.php
touch Test/Case/Model/Behavior/DeletedAtBehaviorTest.php
```

The initial contents of each are pretty simple:

```php
<?php
App::uses('ModelBehavior', 'Model');
class DeletedAtBehavior extends ModelBehavior {
}
?>
```

```php
<?php
App::uses('Model', 'Model');
App::uses('AppModel', 'Model');
require_once CAKE . 'Test' . DS . 'CASE' . DS . 'Model' . DS . 'models.php';
class DeletedAtBehaviorTest extends CakeTestCase {
}
?>
```

Finally, lets enable our plugin so that we can run tests. Add the following to your `bootstrap.php`:

```php
<?php
CakePlugin::load('DeletedAt');
?>
```

Now lets run tests!

```bash
cd path/to/app
Console/cake test DeletedAt AllDeletedAt --stderr
```

You should see exactly 1 failure. We have no tests! But this is good. We now have a barebones behavior, tests that properly fail, and a goal in mind: fully passing tests for our new `DeletedAt` behavior.

Commit your changes and read the next section.

## Writing tests

For our behavior, we want to be able to:

- Mark records as `deleted_at` with a timestamp
- Un-delete records

We'll store this state within a `deleted_at` field on the record. It will be of type `datetime`, and if it is null, then the record is not deleted, otherwise we know when it was soft-deleted.

We'll need a fixture to represent our test model. We should create it using the following:

```bash
cd app/Plugin/DeletedAt
mkdir -p Test/Fixture
touch Test/Fixture/DeletedUserFixture.php
```

> Fixture classes are used to mock out test schemas in the database. They are useful for testing both real-world cases - using the database schema of your production tables - as well as for test-scenarios - as we will use for our plugin.

Fixture classes require two class attributes: `$fields` and `$records`. The `$fields` attribute is used to define the schema for the mocked out table. The `$records` attribute is an array of records to insert into your database. The `$records` attribute should have values specified for each field in `$fields`, otherwise the behavior would be unknown. We'll use the following for our fixture:

```php
<?php
App::uses('CakeTestFixture', 'TestSuite/Fixture');
class DeletedUserFixture extends CakeTestFixture {

  public $fields = array(
    'id' => array('type' => 'integer', 'key' => 'primary'),
    'user' => array('type' => 'string', 'null' => true),
    'password' => array('type' => 'string', 'null' => true),
    'created' => 'datetime',
    'updated' => 'datetime',
    'deleted' => array('type' => 'datetime', 'null' => true),
  );

  public $records = array(
    array('user' => 'mariano', 'password' => '5f4dcc3b5aa765d61d8327deb882cf99', 'created' => '2007-03-17 01:16:23', 'updated' => '2007-03-17 01:18:31', 'deleted' => '2007-03-18 10:45:31'),
    array('user' => 'nate', 'password' => '5f4dcc3b5aa765d61d8327deb882cf99', 'created' => '2007-03-17 01:18:23', 'updated' => '2007-03-17 01:20:31', 'deleted' => null),
    array('user' => 'larry', 'password' => '5f4dcc3b5aa765d61d8327deb882cf99', 'created' => '2007-03-17 01:20:23', 'updated' => '2007-03-17 01:22:31', 'deleted' => null),
  );

}
?>
```

Now lets write a test just for our sanity. We need to prepare our test class with the following:

- A `$fixtures` property to notify PHPUnit as to what fixtures to load for our tests
- A `setUp()` method to execute before each test. We'll setup our model here.
- A `tearDown()` method to execute after each test. We'll destroy our model here to ensure the next test case has a clean environment.

I've taken the liberty of writing these for you, and you can copy the following into your `DeletedAtBehavior` test file:


```php
<?php
  public $fixtures = array(
    'plugin.deleted_at.deleted_user'
  );

  public function setUp() {
    parent::setUp();
    $this->DeletedUser = ClassRegistry::init('User');
    $this->DeletedUser->useTable = 'deleted_users';
    $this->DeletedUser->Behaviors->load('DeletedAt.DeletedAt');
  }

  public function tearDown() {
    unset($this->DeletedUser);
    parent::tearDown();
  }
?>
```

Now lets add a test. We'll find all `deleted` and `non-deleted` records:

```php
<?php
  public function testFindDeleted() {
    $records = $this->DeletedUser->find('all', array(
      'conditions' => array('deleted <>' => null)
    ));
    $this->assertEqual(1, count($records));
  }

  public function testFindNonDeleted() {
    $records = $this->DeletedUser->find('all', array(
      'conditions' => array('deleted' => null)
    ));
    $this->assertEqual(2, count($records));
  }
?>
```

Running `Console/cake test DeletedAt AllDeletedAt --stderr` should give you a single passing test! Yay! Now lets write some real model code.

## Custom Finds

To simplify our logic, we will not be overriding the build-in `Model::delete()` method. Instead, we'll do the following:

- Add a custom finder to find deleted and non-deleted records
- Add a custom method to softdelete and un-softdelete records

Here is some code to handle custom finds in a behavior. It comes from my earlier post on [embedding custom finds within behaviors](/2010/12/01/embedding-custom-finds-in-behaviors/), with relevant updates for 2.x.

```php
<?php
  public $mapMethods = array(
    '/findDeleted/' => 'findDeleted',
    '/findNon_deleted/' => 'findNonDeleted',
  );

  public function setup(Model $model, $config = array()) {
      $model->_findMethods['deleted'] = true;
      $model->_findMethods['non_deleted'] = true;
  }

  public function findDeleted(&$model, $functionCall, $state, $query, $results = array()) {
      if ($state == 'before') {
        if (empty($query['conditions'])) {
          $query['conditions'] = array();
        }
        $query['conditions']["{$model->alias}.deleted <>"] = null;
        return $query;
      }
      return $results;
  }

  public function findNonDeleted(&$model, $functionCall, $state, $query, $results = array()) {
      if ($state == 'before') {
        if (empty($query['conditions'])) {
          $query['conditions'] = array();
        }
        $query['conditions']["{$model->alias}.deleted"] = null;
        return $query;
      }
      return $results;
  }
?>
```

Now that we have our custom finds in place, let's modify our tests to use them:

```php
<?php
  public function testFindDeleted() {
    $records = $this->DeletedUser->find('deleted');
    $this->assertEqual(1, count($records));
  }

  public function testFindNonDeleted() {
    $records = $this->DeletedUser->find('non_deleted');
    $this->assertEqual(2, count($records));
  }
?>
```

Running `Console/cake test DeletedAt AllDeletedAt --stderr` should give us two passing tests!

## Deleting records

Now we'll add two custom methods. Create the following tests:

```php
<?php
  public function testSoftdelete() {
    $this->DeletedUser->softdelete(1);
    $deleted = $this->DeletedUser->find('deleted');
    $nonDeleted = $this->DeletedUser->find('non_deleted');
    $this->assertEqual(1, count($deleted));
    $this->assertEqual(2, count($nonDeleted));

    $this->DeletedUser->softdelete(2);
    $deleted = $this->DeletedUser->find('deleted');
    $nonDeleted = $this->DeletedUser->find('non_deleted');
    $this->assertEqual(2, count($deleted));
    $this->assertEqual(1, count($nonDeleted));

    $this->DeletedUser->softdelete(3);
    $deleted = $this->DeletedUser->find('deleted');
    $nonDeleted = $this->DeletedUser->find('non_deleted');
    $this->assertEqual(3, count($deleted));
    $this->assertEqual(0, count($nonDeleted));
  }

  public function testUnDelete() {
    $this->DeletedUser->undelete(3);
    $deleted = $this->DeletedUser->find('deleted');
    $nonDeleted = $this->DeletedUser->find('non_deleted');
    $this->assertEqual(1, count($deleted));
    $this->assertEqual(2, count($nonDeleted));

    $this->DeletedUser->undelete(2);
    $deleted = $this->DeletedUser->find('deleted');
    $nonDeleted = $this->DeletedUser->find('non_deleted');
    $this->assertEqual(1, count($deleted));
    $this->assertEqual(2, count($nonDeleted));

    $this->DeletedUser->undelete(1);
    $deleted = $this->DeletedUser->find('deleted');
    $nonDeleted = $this->DeletedUser->find('non_deleted');
    $this->assertEqual(0, count($deleted));
    $this->assertEqual(3, count($nonDeleted));
  }
?>
```

Running tests now should give you two successes - our previous tests - and two failures - the new tests. The new tests fail because CakePHP will map `undelete` and `softdelete` to database methods if they don't exist - which is useful in some cases, but in our case, we'll implement the methods.

The logic for these methods is below. Feel free to extend them to your hearts content:

```php
<?php
  public function softdelete(Model $model, $id = null) {
    if ($id) {
      $model->id = $id;
    }

    if (!$model->id) {
      return false;
    }

    $deleteCol = 'deleted';
    if (!$model->hasField($deleteCol)) {
      return false;
    }

    $db = $model->getDataSource();
    $now = time();

    $default = array('formatter' => 'date');
    $colType = array_merge($default, $db->columns[$model->getColumnType($deleteCol)]);

    $time = $now;
    if (array_key_exists('format', $colType)) {
      $time = call_user_func($colType['formatter'], $colType['format']);
    }

    if (!empty($model->whitelist)) {
      $model->whitelist[] = $deleteCol;
    }
    $model->set($deleteCol, $time);
    return $model->saveField($deleteCol, $time);
  }

  public function undelete(Model $model, $id = null) {
    if ($id) {
      $model->id = $id;
    }

    if (!$model->id) {
      return false;
    }

    $deleteCol = 'deleted';
    if (!$model->hasField($deleteCol)) {
      return false;
    }

    $model->set($deleteCol, null);
    return $model->saveField($deleteCol, null);
  }
?>
```

Now lets run tests using `Console/cake test DeletedAt AllDeletedAt --stderr`. You should get the following output:

![http://cl.ly/image/1T010S2J390f](http://cl.ly/image/1T010S2J390f/Screen%20Shot%202013-12-21%20at%205.03.38%20PM.png)

Commit your changes and push to github. We're done!

## Going Further

Any of the following things would be cool to see:

- Moving the softdeletion code to `Model::delete()` and having two consecutive `delete()` calls actually delete the record
- Configuration for the `deleted` column.
- Tracking deletion state over time within a different table.

Of course, you are free to continue with this plugin as you wish! Hopefully the above post clarified some things regarding writing testable CakePHP code, creating plugins, and using/abusing Behaviors within CakePHP.
