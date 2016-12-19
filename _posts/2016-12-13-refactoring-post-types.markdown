---
  title:       "Refactoring Post Types"
  date:        2016-12-13 12:40
  description: "Part 13 of a series of posts that will help you build out a personal CMS"
  category:    cakephp
  tags:
    - refactoring
    - cakeadvent-2016
    - cakephp
  comments:    true
  sharing:     true
  published:   true
  layout:      post
  disable_advertisement: true
  series:      CakeAdvent-2016
---

A friend of mine asked for a custom website, so here I am, writing a custom cms. I know, there are plenty of systems out there that would handle his needs, but it's also a good excuse to play around with CakePHP 3, so here we are.

> For the lazy, the codebase we'll be working on will be available on [GitHub](https://github.com/josegonzalez/cakeadvent-2016). I will be pushing each set of changes on the date when each blog post in this series is published. No cheating!

## Updating Plugins

Before we continue, lets be sure we've updated all our plugins. I like to do this each day so that I can get any bugfixes that come out for libraries my application depends upon. If there are any bugfixes for dependencies, we'll grab those with the following `composer` command:

```shell
composer update
```

Typically you would run tests at this stage, but since we have _yet_ to write any, that isn't necessary.

Let's commit any updates:

```shell
git add composer.lock
git commit -m "Update unpinned dependencies"
```

> You should always verify your application still works after upgrading dependencies.

## Duplicative Logic

In the process of adding a new post type, I noticed that there is a bit of duplication between the `PostsListener::beforeSave()` and the `AbstractPostType::_execute()` method. Specifically, we're not even using the `_execute()` logic in our save. I'm going to refactor it with the following goals:

- Save logic belongs with Crud, so it will be removed from both the `PostsListener` and `AbstractPostType` classes.
- Extra data from the request should be injected at the `PostsListener` level.
- The data that we'll actually save should be returned by the `AbstractPostType::execute()` method.
- We should be able to lean on our `PostType` validation rules as much as possible.

### Dropping extra code in `PostsListener::beforeSave()`

This is the `PostsListener::beforeSave()`

```php
/**
 * Before Save
 *
 * @param \Cake\Event\Event $event Event
 * @return void
 */
public function beforeSave(Event $event)
{
    $type = $event->subject->entity->type;
    if (empty($type)) {
        $passedArgs = $this->_request()->param('pass');
        $type = $passedArgs[0];
    }

    $event->subject->entity->type = $type;

    $data = [
        'user_id' => $this->_controller()->Auth->user('id'),
        'type' => $type,
    ] + $this->_request()->data() + ['published_date' => Time::now()];
    $postType = $event->subject->entity->getPostType();
    $data = $postType->execute($data);

    $PostsTable = TableRegistry::get('Posts');
    $PostsTable->patchEntity($event->subject->entity, $data);
}
```

In it, you'll see I can still inject data from the request - `user_id`, `type`, `published_date` - but also get the "real" data from the specific `PostType::execute()` method. As it's the `Crud.beforeSave` event, we don't actually need to save data, and just patching it onto the event's entity is enough.

### Restructuring `AbstractPostType::_execute()`

This is my new `AbstractPostType::_execute()` method:

```php
protected function _execute(array $data)
{
    if (empty($data['post_attributes'])) {
        $data['post_attributes'] = [];
    }

    $PostsTable = TableRegistry::get('Posts');
    $AttributesTable = TableRegistry::get('PostAttributes');
    $postAttributes = $data['post_attributes'];

    $postColumns = $PostsTable->schema()->columns();
    $validColumns = $this->schema()->fields();
    foreach ($data as $key => $value) {
        if (in_array($key, $postColumns)) {
            continue;
        }

        unset($data[$key]);
        if (!in_array($key, $validColumns)) {
            continue;
        }
        $postAttributes[] = [
            'name' => $key,
            'value' => $value,
        ];
    }

    $data['post_attributes'] = $postAttributes;

    return $data;
}
```

A bit more going on here:

- We're assuming there will *always* be at least an empty set of `post_attributes`.
- If a key is both not a valid post column and not a valid post-type field, then we drop it.
- We're no longer creating a `PostAttribute` Entity, and instead allowing the `PostsTable->patchEntity()` call in the `PostsListener::beforeSave()` to properly martial the data.

With these two changes in place, you can test saving a post and everything should be just fine. Let's commit:

```shell
git add src/Listener/PostsListener.php src/PostType/AbstractPostType.php
git commit -m "Clean up post marshalling and saving"
```

### Allowing Post Data Modification

In our upcoming post type - the PhotoPostType - we'll need to save the file to disk and also ensure we track a `photo_path` that can be used to display the image. This is a bit more logic than our automated system will handle, so we'll need an extra function call to perform these modifications. I've added the following method to `AbstractPostType`:

```php
public function transformData($data)
{
    return $data;
}
```

By default, my `AbstractPostType::transformData()` is a no-op. And I call it *right* after I set a default for `post_attributes` in `AbstractPostType::_execute()`

```php
$data = $this->transformData($data);
```

Why can't I just depend upon the UploadBehavior to do this logic for me? Many behaviors end up changing where things are stored in the `Table.beforeSave` event, which happens *after* the `Crud.beforeSave` event. This means that we'd end up trashing the upload data before the `UploadBehavior` can handle it. As well, that behavior doesn't know anything about our weird `post_attributes` system, so we'd need to handle the logic on our own.

I'll save my changes for now, and get to add a custom `PhotoPostType` tomorrow.


```shell
git add src/PostType/AbstractPostType.php
git commit -m "Allow post types to transform the data before it is further marshalled"
```

---

> For those that may just want to ensure their codebase matches what has been done so far, the codebase is available on GitHub and tagged as [0.0.13](https://github.com/josegonzalez/cakeadvent-2016/tree/0.0.13).


A bit of light refactoring is always useful to get your application priorities in order. In this case, it was absolutely necessary in order to figure out where exactly we'd need to hook in for our custom photo type.

Be sure to follow along via twitter on [@savant](https://twitter.com/savant). If you'd like to subscribe to this blog, you may follow the [rss feed here](/atom.xml). Also, all posts in the series will be conveniently linked on the sidebar of every post in the 2016 CakeAdvent Calendar. Come back tomorrow for more delicious content.
