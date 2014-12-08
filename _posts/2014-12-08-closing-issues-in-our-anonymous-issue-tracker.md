---
  title:       "Closing Issues in our Anonymous Issue Tracker using Events"
  date:        2014-12-08 17:31
  description: "Part 7 of 7 in a series of posts designed to teach you how to use CakePHP 3 effectively"
  category:    CakePHP
  tags:
    - cakeadvent-2014
    - cakephp
  comments:    true
  sharing:     true
  published:   true
  layout:      post
  series:      CakeAdvent-2014
---

One thing that you'll want to eventually handle is closing issues. We'll do this using a simple Event. We need to first add the following migration to handle whether an issue is closed or not:

```php
<?php
use Phinx\Migration\AbstractMigration;

class ClosingIssues extends AbstractMigration {
  public function change() {

    $table = $this->table('issues');
    $table
      ->addColumn('is_closed', 'boolean', [
        'default' => false,
      ])
      ->save();
  }
}
?>
```

You'll want to run the migration and clear your orm cache:


```shell
bin/cake migrations migrate
bin/cake orm_cache clear
```

Finally, you should add this field to the `IssueEntity::$_accessible` array.

Whenever an issue has it's `is_closed` field set to true in the database (1 in mysql), then we should disable commenting on said entity. We can do this by hooking into the `Model.beforeValidate` event in our `app/config/events.php` file:

```php
use App\Model\Entity\Comment;

EventManager::instance()->attach(function (Event $event, Entity $entity, ArrayObject $options) {
    if (!($entity instanceof Comment)) {
        return true;
    }

    $table = TableRegistry::get('Issues');
    $open_issue = $table->find('all')->where([
        'Issues.id' => $entity->issue_id,
        'Issues.is_closed' => false,
    ])->first();

    return !empty($open_issue);
}, 'Model.beforeValidate');
```

A bit of explanation:

- We're only going to trigger this event for `Comment` entities, hence the `instanceof` check
- Since we only want to allow commenting on open issues, we need to find the entity matching our comment's issue only if `is_closed` is false.
- If an event returns false, then `Event->stopPropagation` is automatically called. For the `Model.beforeValidate` event, if the event is stopped, then the validation fails, so therefore if the `open_issue` is empty, then we fail validation.

Quite simple! We can refactor this into a validation rule, but we will avoid doing so for now as validation is currently being refactored in 3.x.

## Homework time!

A few more things you'll want to do:

- Provide some interface to actually close an issue. You can perhaps place this functionality behind basic auth, build a cake shell to handle closing issues, or simply allow anyone to close issues. It's up to you.
- You need to hide the form if the issue is closed. You can do this by modifying your bake templates to handle this case and rebaking.

With the above change, our anonymous issue tracker is "feature-complete". We've covered quite a bit of CakePHP in building this application, but are definitely many more features to cover. Stay tuned for the next tutorial series, where we'll cover creating an ecommerce store from scratch, including use authentication, payment processing and more!

Be sure to follow along as via twitter on [@savant](https://twitter.com/savant). If you'd like to subscribe to this blog, you may follow the [rss feed here](http://josediazgonzalez.com/atom.xml). Also, all posts in the series will be conveniently linked on the sidebar of every post in the 2014 CakeAdvent Calendar.
