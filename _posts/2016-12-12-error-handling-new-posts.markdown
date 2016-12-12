---
  title:       "Error Handling new Posts"
  date:        2016-12-12 12:06
  description: "Part 12 of a series of posts that will help you build out a personal CMS"
  category:    cakephp
  tags:
    - elements
    - events
    - viewblocks
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

Before we continue, lets be sure we've updated all our plugins. I like to do this each day so that I can get any bugfixes that come out for libraries my application depends upon. In this case, there are a few bugfixes for some CakePHP plugins, so we'll grab those with the following `composer` command:

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

## Today's todolist

We'll take care of the following two items today.

- Only showing action buttons to add valid post types.
- Redirecting when a new post is being added with an unspecified or invalid type.

### Modifying shown buttons

On the `/posts` page, we currently show an `Add` button and a `Home` button. We should only show Add buttons, but *only* for post types that exist. To do so, we'll replace the scaffolded `actions` viewblock with one that contains valid action urls. I've added the following to our `PostsListener::beforeHandleIndex()`:

```php
$this->_controller()->set('indexActions', $this->_getIndexActions());
$this->_action()->config('scaffold.viewblocks', [
    'actions' => [
        'admin/Posts/index-actions' => 'element',
    ],
]);
```

We're going to rely on a special element - `src/Template/Element/admin/Posts/index-actions.ctp` - to render the variable `indexActions` for any viewblock named `actions`. The contents of the `PostsListener::_getIndexActions()` method is as follows.

```php
/**
 * Get valid actions for the index page
 *
 * @return array
 */
protected function _getIndexActions()
{
    $indexActions = [];
    $postTypes = PostsTable::postTypes();
    foreach ($postTypes as $class => $alias) {
        $indexActions[] = [
            'title' => __('Add {0}', $alias),
            'url' => ['controller' => 'Posts', 'action' => 'add', $alias],
            'options' => ['class' => 'btn btn-default'],
            'method' => 'GET',
        ];
    }
    return $indexActions;
}
```

Pretty straightforward. I retrieve all available `PostType` classes, then return each one as a link.

> Remember to add `use App\Model\Table\PostsTable;` to the top of your class, otherwise you'll get an error regarding the class not existing.

Now on to our `index-actions.ctp` template.

```php
<?php
foreach ($indexActions as $config) {
    echo $this->element('CrudView.action-button', ['config' => $config]);
}
```

Here, I'm relying on the `Crud.action-button` template to render the correct button link, so if that ever changes, we'll get the correct update on our end. Time to commit:

```shell
git add src/Listener/PostsListener.php src/Template/Element/admin/Posts/index-actions.ctp
git commit -m "Only show the buttons we want to show on the /posts page"
```

### Redirecting on bad blog post types

This one is pretty simple. For the `add` action, we should only allow registered post types. This is my modified `PostsListener::beforeRenderAdd()`.

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
    if (!PostsTable::isValidPostType($passedArgs)) {
        return $this->_controller()->redirect([
            'controller' => 'Posts',
            'action' => 'index',
        ]);
    }

    $event->subject->entity->type = $passedArgs[0];
    $this->_setPostType($event, $event->subject->entity->getPostType());
}
```

Next, here is the method that checks if the PostType is valid. I've added it to the `PostTypesTrait` that is used in the `PostsTable`.

```php
/**
 * Checks if the passed arguments contain a valid post type
 *
 * @param string $passedArgs a list of passed request parameters
 * @return bool
 */
public static function isValidPostType($passedArgs)
{
    if (empty($passedArgs[0])) {
        return false;
    }

    $validPostType = false;
    $postTypes = PostsTable::postTypes();
    foreach ($postTypes as $class => $alias) {
        if ($passedArgs[0] === $alias) {
            $validPostType = true;
            break;
        }
    }
    return $validPostType;
}
```

Now we should redirect back *even if* the user tries to set an invalid post type.


## Homework!

Create a validation rule for the `PostsTable` that only allows `type` to be a valid post type. Good luck!

---

> For those that may just want to ensure their codebase matches what has been done so far, the codebase is available on GitHub and tagged as [0.0.12](https://github.com/josegonzalez/cakeadvent-2016/tree/0.0.12).


We're quickly wrapping up our blog's admin panel. While there will definitely be a few more things to do to clean up the UI, it's in great shape now. We'll be turning our attention to the other post types now, which hopefully won't require too many additions.

Be sure to follow along via twitter on [@savant](https://twitter.com/savant). If you'd like to subscribe to this blog, you may follow the [rss feed here](/atom.xml). Also, all posts in the series will be conveniently linked on the sidebar of every post in the 2016 CakeAdvent Calendar. Come back tomorrow for more delicious content.
