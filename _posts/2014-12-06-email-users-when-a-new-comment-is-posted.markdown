---
  title:       "Emailing users when a new comment is posted"
  date:        2014-12-06 13:45
  description: "Part 5 of 7 in a series of posts designed to teach you how to use CakePHP 3 effectively"
  category:    cakephp
  tags:
    - cakeadvent-2014
    - cakephp
    - custom-find
    - email
    - entities
  comments:    true
  sharing:     true
  published:   true
  layout:      post
  series:      CakeAdvent-2014
---

> The previous post had `IssuesTable.afterSave` as the event in use. We've changed this to `CommentsTable.afterSave` to better reflect what is occurring.

Similar to yesterday, we'll want to *also* notify users via email. If a user has specified their email address, we'll want to notify them at their email address. Lets start by adding a new event to our `app/config/events.php` file. It will follow the same basic pattern as the previous event. Here the previous event is for your recollection:

```php
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
}, 'IssuesTable.afterSave');
```

The only part we're going to change is *how* we send the data - rather than via a POST, it will send an email. A couple notes:

- The find is being duplicated each time
- We're going to unset the `email_address` and `webhook_url` fields from the data array both times

Boo. Code duplication that will probably happen again if we implement more callback-types. To reduce this, we're going to add a custom finder to simplify our find call, and then a custom method to our Comment Entity class to output the public data.

### Custom finders

In CakePHP 3, custom finders are simply methods that return custom query objects. As a result, hey are a bit simpler to manipulate than in CakePHP 2. Since our find call above was simply a query object manipulator, it will be quite simple to transform that into a custom find in our `app/src/Model/Table/CommentsTable.php` file:

```php
// You can move the `\App\Model\Entity\Comment` to a `use` call at the top
// of the class and then reference it with `Comment` in the `instanceof` check
public function findNotifiable(Query $query, array $options) {
    if (empty($options['comment']) || !($options['comment'] instanceof \App\Model\Entity\Comment)) {
        throw new \InvalidArgumentException('Missing comment entity argument');
    }
    if (empty($options['notifierField']) {
        throw new \InvalidArgumentException('Missing notifierField argument');
    }

    return $query->where([
        'Comments.id !=' => $options['comment']->id,
        'Comments.issue_id' => $options['comment']->issue_id,
        "Comments.{$options['notifierField']} IS NOT" => null,
    ]);
}
```

If you place the above in your `CommentsTable` class, you can now call the custom find in the following way:

```php
$table = TableRegistry::get('Comments');
$comments = $table->find('notifiable', [
    'comment' => $comment
    'notifierField' => 'webhook_url'
]);
```

While this allows you easily replace the `Model::beforeFind()` in 2.x, you will need to use [map/reduce](http://book.cakephp.org/3.0/en/orm/query-builder.html#map-reduce) functions to simulate `Model::afterFind()`. Note that you can place these within the custom finder as well, just that their syntax is a little different. We'll explore them in a future post.

### Custom entity methods

Entities are simply objects returned by the ORM. Pretty straightforward. They replace the former array structure returned by a `Model::find()`, allowing developers to add custom methods to the base objects, making dealing with data representation a bit easier. In our case, we're going to wrap the `Comment::toArray()` method with our own logic for setting property data:

```php
public function toPublicArray() {
  $data = $this->toArray();
  unset($data['email_address']);
  unset($data['webhook_url']);
  return $data;
}
```

Adding the above to our `app/src/Model/Entity/Comment.php` file will allow us to use the method in our code like so:

```php
$comment = $table->find('all')->first();
$publicData = $comment->toPublicArray();
```

An *alternative* is to modify the `$_hidden` property of the Entity. This property will hide a field from the output of `$entity->toArray()` and `json_encode($entity)`:

```php
<?php
namespace App\Model\Entity;

use Cake\ORM\Entity;
class Comment extends Entity {
  protected $_hidden = ['email_address', 'webhook_url'];

  // other code here
}
?>
```

With the above, we can continue using the `$entity->toArray()` method of data retrieval without worrying about whether the data being output contains sensitive information.

Going forward, we'll assume you used the `$_hidden` method.

### A reimagined event:

Now that we have the basics in place, our original webhook event looks like the following:

```php
use Cake\Event\Event;
use Cake\Event\EventManager;
use Cake\Network\Http\Client;
use Cake\ORM\Entity;
use Cake\ORM\TableRegistry;

EventManager::instance()->attach(function (Event $event, Entity $entity, ArrayObject $options) {
    $comments = TableRegistry::get('Comments')->find('notifiable', [
        'comment' => $entity,
        'notifierField' => 'webhook_url'
    ]);
    foreach ($comments as $comment) {
        $http = new Client();
        $http->post($comment->webhook_url, json_encode($comment), [
          'type' => 'json'
        ]);
    }
}, 'IssuesTable.afterSave');
```

*Much* nicer.

### Sending email

To send email, you'll need to [configure an email transport](http://book.cakephp.org/3.0/en/core-libraries/email.html#configuring-transports). I'm going assume you did that (gmail via smtp should work fine) so we'll skip ahead to the actual email sending. Our new event will *also* be in the `app/config/event.php` file, so we only need to call `use` on one more class:

```php
use Cake\Network\Email\Email;

EventManager::instance()->attach(function (Event $event, Entity $entity, ArrayObject $options) {
    $comments = TableRegistry::get('Comments')->find('notifiable', [
        'comment' => $entity,
        'notifierField' => 'email_address'
    ]);
    foreach ($comments as $comment) {
        $email = new Email();
        $email->from(['me@example.com' => 'Anonymous Issues'])
            ->to($comment->email_address)
            ->subject(sprintf("New comment on issue #%d", $comment->issue_id))
            ->send($comment->comment);
    }
}, 'IssuesTable.afterSave');
```

The above is a contrived example of email sending. You could subclass the email class into a `NotificationEmail` class and have it take a `Comment` entity directly - as well as add custom logic around the message body or other configuration - but we'll leave that as an exercise for larger applications.

> While this and the previous tutorial show how to make http requests and notifications in a web request, it may be prudent to move these into background tasks to keep the application responsive. We'll look into doing just that in a separate post, but keep in mind that performing longer tasks in a web request is ill-advised.

### Homework Time!

Lazy sunday tomorrow, so go do something for yourself. [Here is a link](http://littleanimalgifs.tumblr.com/random) to random animal gifs. Until next time!
