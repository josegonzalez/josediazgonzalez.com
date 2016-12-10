---
  title:       "Making the UI usable"
  date:        2016-12-10 9:32
  description: "Part 10 of a series of posts that will help you build out a personal CMS"
  category:    cakephp
  tags:
    - custom-find
    - crud-view
    - refactoring
    - templates
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

## Errata from previous posts

- The `AbstractPostType` class had errors in how it retrieved templates for a `PostType`.
- The `Template` directory for the `BlogPostType` plugin was misnamed to `Templates`.
- There was no way to pre-seed data in a post-type instance for `get()` calls.
- If the passed in `Post` object for a `PostType` was missing `post_attributes`, an error would appear

Thanks to those who've pointed out my derps. These fixes are available as the first commit in the current release.

## Fixing Incongruity

While we have a semblance of working code, a lot of it is a bit all over the place.:

- We broke rendering of the home page (`/`).
- There isn't a way to go directly to adding a blog post, and instead we have to type out the url.
- The login screen looks different from the rest of the site.
- The `/users/edit` page has the wrong look and wrong sidebar.
- We don't error check when there is no `PostType` set for adding a post.
- Our default user-facing theme is, well, lame. No offense CakePHP team, it's just not the best default theme.

Over the next few posts, let's fix some of these ux issues.

## Refactoring PostType retrieval

Before we can setup the home page properly, we'll need to refactor how we retrieve the PostType. I'd really rather not have a bunch of duplicated logic in our template layer when it can very easily go in a helper or elsewhere. I'm going to centralize retrieving the `PostType` for an entity

Now, lets make sure we can retrieve the correct element to display our `PostType`. I'll do so via a Trait on the `Post` entity.

### Preparing Traits

Looking back at my codebase, I noticed that the `Table` directory has a subdirectory for traits, but `Entity` does not. Let's correct that.

```shell
mkdir -p src/Model/Entity/Traits
git mv src/Model/Entity/PasswordHashingTrait.php src/Model/Entity/Traits/
```

Also, update the reference in your `User` entity for using this trait:

```php
use \App\Model\Entity\Traits\PasswordHashingTrait;
```

And update the namespace on that trait, or you're gonna have a bad time:

```php
namespace App\Model\Entity\Traits;
```

Committing!

```shell
git add src/Model/Entity/User.php
git commit -m "Move PasswordHashingTrait to correct location"
```

### Getting the `PostType` from a Post Entity

This is going to be a bit of refactoring. First, we're going to add the `PostTypesTrait` to our `PostsTable`. We'll also move it into the correct directory.

```shell
git mv src/Traits/PostTypesTrait.php src/Model/Table/Traits/
```

Now add it to the table:

```php
use \App\Model\Table\Traits\PostTypesTrait;
```

And update the namespace on that trait, or you're gonna have a bad time:

```php
namespace App\Model\Table\Traits;
```

Next, we'll remove it from the `PostsListener`. This will temporarily break the application, but bear with me. Once that's done, we can start working on making it so a `Post` entity knows what `PostType` it has, and can return it. I've created the following `PostTypeTrait` at `src/Model/Entity/Traits/PostTypeTrait.php`:

```php
<?php
namespace App\Model\Entity\Traits;

use App\Model\Entity\Post;
use App\Model\Table\PostsTable;
use Cake\Core\App;

trait PostTypeTrait
{
    public function getPostType()
    {
        $postTypeClassName = $this->_postTypeAliasToClass($this->type);
        $className = App::className($postTypeClassName, 'PostType');
        return new $className($this);
    }

    /**
     * Returns a class name for a given post type alias
     *
     * @param string $typeAlias the alias of a post type class
     * @return string
     */
    protected function _postTypeAliasToClass($typeAlias)
    {
        $className = null;
        $postTypes = PostsTable::postTypes();
        foreach ($postTypes as $class => $alias) {
            if ($alias === $typeAlias) {
                $className = $class;
            }
        }
        return $className;
    }
}
```

You'll notice I took `_postTypeAliasToClass` from `PostsListener` and modified it to use the `PostsTable` instead. I believe this a better place to put it, but feel free to argue with me. I'll also remove `PostsListener::_postTypeAliasToClass()`, as we'll be refactoring the `PostsListener` to use my new setup.

Add the above trait *inside* of your `Post` entity class:

```php
use \App\Model\Entity\Traits\PostTypeTrait;
```

Lets commit our changes for now.

```shell
git add src/Listener/PostsListener.php src/Model/Entity/Post.php src/Model/Entity/Traits/PostTypeTrait.php src/Model/Table/PostsTable.php src/Traits/PostTypesTrait.php -> src/Model/Table/Traits/PostTypesTrait.php
git commit -m "Move post type retrieval into the Post entity"
```

### Refactoring PostsListener

Because we've basically kneecapped our `PostsListener`, the whole admin is probably flipping a crap. I'll begin by changing `PostsListener::_setPostType()` to accept an `AbstractPostType` instance. Add the following `use` call to the top of the `PostsListener` class declaration:

```php
use App\PostType\AbstractPostType;
```

Next, change the `PostsListener::_setPostType()` method to the following:

```php
/**
 * Set the post type for add/edit actions
 *
 * @param \Cake\Event\Event $event Event
 * @param string $postType the name of a post type class
 * @return void
 */
protected function _setPostType(Event $event, AbstractPostType $postType)
{
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

Now we need to fix all references to this method. I've changed `PostsListener::beforeRenderAdd()` almost completely, and it's much smaller.

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
    $event->subject->entity->type = $passedArgs[0];
    $this->_setPostType($event, $event->subject->entity->getPostType());
}
```

`PostsListener::beforeRenderEdit()` gets a similar facelift.

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
    $this->_setPostType($event, $entity->getPostType());
    if ($this->_request()->is('get')) {
        $this->_request()->data = $event->subject->entity->data($entity);
    }
}
```

Finally, the `PostsListener::beforeSave()` method needs a minor change. Right after we set the `type` on the entity, we'll remove the following three lines and replace them with:

```php
$postType = $event->subject->entity->getPostType();
```

That's it, our admin dashboard should be in working order again. Let's save our work:

```shell
git add src/Listener/PostsListener.php
git commit -m "Fix PostsListener"
```

## Render `/` properly

Our user will rely heavily on themes, but the default state of the blog should be useful. First, lets remove the `PostsController::home()` action and use the default template for the view layer. I've created `src/Templates/Posts/home.ctp` with the following contents (feel free to replace what is already there):

```php
<div class="posts index large-12 medium-12 columns content">
    <h3><?= __('Posts') ?></h3>
    <?php
        foreach ($posts as $post) {
            $postType = $post->getPostType();
            echo $this->element($postType->indexTemplate(), ['post' => $postType]);
        }
    ?>
</div>
```

If you go to the homepage, you'll see a bunch of posts, but no actual content for each, even though the `BlogPostType` index template displays the `body`. What gives?

Well, the default find for this view *does not* include related data. This can be easily ameliorated by using a custom find. As I've done before, I'll create a trait for it in `src/Model/Table/Traits/BlogFinderTrait.php`:

```php
<?php
namespace App\Model\Table\Traits;

trait BlogFinderTrait
{
    /**
     * Find posts with related data
     *
     * @param \Cake\ORM\Query $query The query to find with
     * @param array $options The options to find with
     * @return \Cake\ORM\Query The query builder
     */
    public function findBlog($query, $options)
    {
        return $this->find()->contain('PostAttributes');
    }
}
```

Simple enough. Let's add it *inside* our `PostsTable` class:

```php
use \App\Model\Table\Traits\BlogFinderTrait;
```

Finally, we'll need to ensure our finder is in use for the `PostsController::home()` action. We'll add a special case to our `PostsListener::beforeHandle()`:

```php
if ($this->_controller()->request->action === 'home') {
    $this->beforeHandleHome($event);

    return;
}
```

And here is the `PostsListener::beforeHandleHome()`:

```php
/**
 * Before Handle Home Action
 *
 * @param \Cake\Event\Event $event Event
 * @return void
 */
public function beforeHandleHome(Event $event)
{
    $this->_action()->config('findMethod', 'blog');
}
```

And now you can go to `/` and you'll see all of our blog posts! We'll commit our changes for today as we're done here.

```shell
git add src/Controller/PostsController.php src/Listener/PostsListener.php src/Model/Table/PostsTable.php src/Model/Table/Traits/BlogFinderTrait.php src/Template/Posts/home.ctp
git commit -m "Finally working homepage"
```

---

> For those that may just want to ensure their codebase matches what has been done so far, the codebase is available on GitHub and tagged as [0.0.10](https://github.com/josegonzalez/cakeadvent-2016/tree/0.0.10).

We've refactored quite a bit of code, but still have a few things to fix up before we can go back to building out more custom post types. Hopefully we can make quick work of the rest of our todo list.

Be sure to follow along via twitter on [@savant](https://twitter.com/savant). If you'd like to subscribe to this blog, you may follow the [rss feed here](/atom.xml). Also, all posts in the series will be conveniently linked on the sidebar of every post in the 2016 CakeAdvent Calendar. Come back tomorrow for more delicious content.
