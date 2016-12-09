---
  title:       "Saving Custom Post Types"
  date:        2016-12-09 10:40
  description: "Part 9 of a series of posts that will help you build out a personal CMS"
  category:    cakephp
  tags:
    - crud
    - events
    - forms
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

## Errata from previous post

- The `AbstractPostType` class is missing the `use App\Model\Entity\Post;` statement in the class declaration.
- Added `unset($data['user']);` to `AbstractPostType::data()`.

Thanks to those who've pointed out my derps. These fixes are available as the first commit in the current release.

## Updating Plugins

Before we continue, lets be sure we've updated all our plugins. I like to do this each day so that I can get any bugfixes that come out for libraries my application depends upon. In this case, there are a few bugfixes for some CakePHP plugins, so we'll grab those with the following `composer` command:

```php
composer update
```

Typically you would run tests at this stage, but since we have _yet_ to write any, that isn't necessary.

Let's commit any updates:

```shell
git add composer.lock
git commit -m "Update unpinned dependencies"
```

> You should always verify your application still works after upgrading dependencies.

## Handling Edits

Our previous post only handled the `add` action, while we'll need to also support the `edit` action. I've extracted the logic necessary for both into the `PostsListener::_setPostType()` method.

```php
/**
 * Set the post type for add/edit actions
 *
 * @param \Cake\Event\Event $event Event
 * @param string $postType the name of a post type class
 * @return void
 */
protected function _setPostType(Event $event, $postType)
{
    $className = App::className($postType, 'PostType');
    $postType = new $className;
    $fields = [];
    foreach ($postType->schema()->fields() as $field) {
        $fields[$field] = [
            'type' => $postType->schema()->fieldType($field)
        ];
    }

    $viewVars = $postType->viewVars();
    $viewVars['fields'] = $fields;
    $this->_controller()->set($viewVars);
    $event->subject->set(['entity' => $postType]);
}
```

As well, I moved the alias to class name mapping into it's own function so that it can be used for the edit action:

```php
/**
 * Returns a class name for a given post type alias
 *
 * @param string $typeAlias the alias of a post type class
 * @return string
 */
public function _postTypeAliasToClass($typeAlias)
{
    $className = null;
    $postTypes = PostsListener::postTypes();
    foreach ($postTypes as $class => $alias) {
        if ($alias === $typeAlias) {
            $className = $class;
        }
    }
    return $className;
}
```

I've also added a new `PostsListener::beforeRenderEdit()` method to perform all the logic necessary for setting the correct post type:

```php
/**
 * Before Render Edit Action
 *
 * @param \Cake\Event\Event $event Event
 * @return void
 */
public function beforeRenderEdit(Event $event)
{
    $entity = $event->subject->entity;
    $className = $this->_postTypeAliasToClass($entity->type);
    $this->_setPostType($event, $className);
    if ($this->_request()->is('get')) {
        $this->request->data = $event->subject->entity->data($entity);
    }
}
```

In order to set the post type for an edit action, we need ensure we invoke the `PostsListener::beforeRenderEdit()` method.

Finally, we need to update `PostsListener::beforeRenderAdd()` to:

```php
/**
 * Before Render Add Action
 *
 * @param \Cake\Event\Event $event Event
 * @return void
 */
public function beforeRenderAdd(Event $event)
{
    $passedArgs = $this->_request()->param('pass');
    $className = null;
    if (!empty($passedArgs)) {
        $className = $this->_postTypeAliasToClass($passedArgs[0]);
    }

    if ($className !== null) {
        $this->_setPostType($event, $className);
    }
}
```

Time to commit our changes.

```shell
git add src/Listener/PostsListener.php
git commit -m "Handle both add and edit saves"
```

## Associating a User with a Post

When a post is created or edited, we'll want to ensure that it is properly associated with the current user. This is pretty simple, as we can do this automatically in the `beforeSave`. We'll start by mapping the event handler in our `PostsListener::implementedEvents()` method:

```php
'Crud.beforeSave' => 'beforeSave',
```

And finally, here is the event handler itself. It's pretty straightforward:

```php
/**
 * Before Save
 *
 * @param \Cake\Event\Event $event Event
 * @return void
 */
public function beforeSave(Event $event)
{
    $event->subject->entity->user_id = $this->_controller()->Auth->user('id');
}
```

Commit!

```shell
git add src/Listener/PostsListener.php
git commit -m "Set the user_id to the currently authenticated user"
```

## Saving extra fields in the post_attributes table

Since we have a few extra fields, they all need to be saved as `post_attributes`. The easiest way is to hook into our new `PostsListener::beforeSave()` method and massage the entity. We'll modify our `PostsListener::beforeSave()` to look like the following:

```php
/**
 * Before Save
 *
 * @param \Cake\Event\Event $event Event
 * @return void
 */
public function beforeSave(Event $event)
    $type = $event->subject->entity->type;
    if (empty($type)) {
        $passedArgs = $this->_request()->param('pass');
        $type = $passedArgs[0];
    }

    $event->subject->entity->type = $type;
    $postTypeClassName = $this->_postTypeAliasToClass($type);
    $className = App::className($postTypeClassName, 'PostType');
    $postType = new $className;
    $validFields = $postType->schema()->fields();

    $postAttributes = [];
    $PostsTable = TableRegistry::get('Posts');
    $postColumns = $PostsTable->schema()->columns();
    foreach ($event->subject->entity->toArray() as $field => $value) {
        if (!in_array($field, $postColumns) && in_array($field, $validFields)) {
            $postAttributes[] = [
                'name' => $field,
                'value' => $value,
            ];
        }
    }

    $data = [
        'user_id' => $this->_controller()->Auth->user('id'),
        'type' => $type,
        'post_attributes' => $postAttributes,
    ] + $this->_request()->data;
    if (empty($data['published_date'])) {
        $data['published_date'] = Time::now();
    }

    $PostsTable->patchEntity($event->subject->entity, $data);
}
```

Lots of code there, so lets go over it:

- Still setting the `user_id` to the currently logged in user, just later, and via `PostsTable::patchEntity()`
- We need to retrieve all valid fields for the current post type. Users should *never* be able to save data that we don't expect as extra attributes.
- I'm building an array of `postAttributes` from the set post fields where:
  - the field isn't a column of the `post` entity
  - the field is allowed to be saved for the `PostType`
- I'm setting the default `published_date` to the current time if it isn't already set. We'll come back to this at a later date (pun intended).
- We are patching our `post` entity with the list of postAttributes.

Remember to add the following `use` call to your `PostsListener` class declaration:

```php
use Cake\I18n\Time;
use Cake\ORM\TableRegistry;
```

Dope. You can try going to `/posts/add/blog` to add a blog post, and then edits should also work fine. It's a bit nasty looking, but it'll do for now.

Lets save our work for now.

```shell
git add src/Listener/PostsListener.php
git commit -m "Implement post saving"
```

---

> For those that may just want to ensure their codebase matches what has been done so far, the codebase is available on GitHub and tagged as [0.0.9](https://github.com/josegonzalez/cakeadvent-2016/tree/0.0.9).

Posts can be added and saved hurray! We'll definitely use this as a good base for building out our CMS, and while we don't yet have a way to select a post-type, that should come Real Soon™.

Be sure to follow along via twitter on [@savant](https://twitter.com/savant). If you'd like to subscribe to this blog, you may follow the [rss feed here](/atom.xml). Also, all posts in the series will be conveniently linked on the sidebar of every post in the 2016 CakeAdvent Calendar. Come back tomorrow for more delicious content.
