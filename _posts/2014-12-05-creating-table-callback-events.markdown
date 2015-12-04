---
  title:       "Creating Table Callback Events"
  date:        2014-12-05 17:34
  description: "Part 4 of 7 in a series of posts designed to teach you how to use CakePHP 3 effectively"
  category:    cakephp
  tags:
    - cakeadvent-2014
    - cakephp
    - models
    - events
  comments:    true
  sharing:     true
  published:   true
  layout:      post
  series:      CakeAdvent-2014
---

For yesterday's homework, you should have generated the following migration:

```php
<?php
use Phinx\Migration\AbstractMigration;

class WebookUrl extends AbstractMigration {
  public function change() {

    $table = $this->table('comments');
    $table
      ->addColumn('webhook_url', 'string', [
        'limit' => '255',
        'null' => '1',
        'default' => '',
      ])
      ->save();
  }
}
?>
```

A couple other notes (while CakePHP 3 is still in beta):

- Using the field `unsigned` is currently invalid. You can either remove those designations from your initial migration, or make them the inverse and use `signed`.
- In order to properly disable the automatic `id` field that phinx does, you'll need to remove the following from the initial schema `$table` instantiations:

      ->addColumn('id', 'integer', [
        'limit' => '11',
        'null' => '',
        'default' => '',
      ])

To actually start using migrations from now on, you should drop your existing tables (which is okay since we're starting fresh): and run the following command:

```shell
bin/cake migrations migrate
bin/cake orm_cache clear
```

You will also need to make the `webhook_url` to the `$_accessible` property in your `src/Model/Entity/Issue.php` file. You can do this manually (if you have customizations) or with the bake shell:

```shell
bin/cake bake model comments --force --no-table
```

In future tutorials, we'll avoid these issues, but just keep this in mind for now.

---

Webhooks are actually pretty easy to setup. Whenever a comment is created, we'll want to notify all other comment webhooks that the issue was updated. To do so, we can hook into the `CommentsTable::afterSave()` method.

A `Table::afterSave()` call takes the following arguments:

- `Event $event`: The actual event that is occurring
- `Entity $entity`: The entity that was just saved
- `ArrayObject $options`: An array of options that was passed into the `Table::save()` call.

If you don't create a concrete `afterSave()` method, the event isn't fired on the Table class, so unfortunately we can't bind to the global event easily. Instead, we'll fire a custom `CommentsTable.afterSave` event from our own custom `afterSave()` method:

```php
public function afterSave(Event $event, Entity $entity, ArrayObject $options) {
  $this->dispatchEvent('CommentsTable.afterSave', compact('entity', 'options'));
}
```

You also will want to include the following classes at the top of your table class:

```php
use ArrayObject;
use Cake\Event\Event;
use Cake\Orm\Entity;
```

> In the future, it may be possible to use custom bake events to insert elements into Table and Entity classes. Stay tuned for bake updates!

Now that we've fired our custom event, we can add a new event for it! What I like doing is centralizing my global events in an `app/config/events.php` file, so lets add the following line to the `app/config/bootstrap.php` file:

```php
require __DIR__ . '/events.php';
```

Next, we'll add the following event to our `app/config/events.php` file:

```php
<?php
use Cake\Event\Event;
use Cake\Event\EventManager;
use Cake\Network\Http\Client;
use Cake\ORM\Entity;
use Cake\ORM\TableRegistry;

EventManager::instance()->attach(function (Event $event, Entity $entity, ArrayObject $options) {
    $table = TableRegistry::get('Comments');
    $comments = $table->find('all')->where([
        'Comments.id !=' => $entity->id,
        'Comments.issue_id' => $entity->issue_id,
        'Comments.webhook_url IS NOT' => null,
    ]);
    foreach ($comments as $comment) {
        $data = $comment->toArray();
        unset($data['email_address']);
        unset($data['webhook_url']);

        $http = new Client();
        $http->post($comment->webhook_url, json_encode($data), [
          'type' => 'json'
        ]);
    }
}, 'CommentsTable.afterSave');
?>
```

A lot of new code. Lets disect this a bit:

- When you want an arbitrary Table class, you can use `TableRegistry::get()` to retrieve it.
- The new ORM uses method chaining in order to change the query being used. Note that it is a lazy query, so you need to iterate over the result *or* call the methods `count()`, `all()`, `first()`, or `firstOrFail()` in order to execute the query. Consult the [query builder docs](http://book.cakephp.org/3.0/en/orm/query-builder.html) for more details.
- Every entity has a `toArray()` method, which uses the `Entity::visibleProperties()` method to decide what to expose. You can limit this by adding fields to the `$_hidden` Entity property. Out of laziness, we didn't use any entity features to remove the `email_address` field from the array output. See [array/json conversion docs](http://book.cakephp.org/3.0/en/orm/entities.html#converting-to-arrays-json) if you'd like to do so.
- Every entity is json serializable by default. The EntityTrait class - included in the Entity class - has a `jsonSerialize` method which calls `toArray()`. Pretty nifty.
- CakePHP includes a [simple HttpClient](http://book.cakephp.org/3.0/en/core-libraries/httpclient.html) that you can use to interact with external webservices. It's *quite* useful. In our case, we're specifying that we should post json to the api.

At this point, you'll want to regenerate your `src/Template/Issues/view.ctp` file in order to add the `webhook_url` field to test. You can do so via the following command:

```shell
bin/cake bake view issues --force
```

Now all you need to do is test your integration. You can do so by creating a new issue and adding comments to that issue. If you want to generate a test url, I recommend using the excellent [http://requestb.in/](http://requestb.in/) to make a url that captures your response.

## Homework Time!

There is no homework, it's the weekend :) . Go forth and use your new knowledge to extend your app however you please.
