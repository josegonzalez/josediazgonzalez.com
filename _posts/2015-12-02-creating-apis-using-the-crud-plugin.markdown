---
  title:       "Creating APIs using the CRUD Plugin"
  date:        2015-12-02 13:42
  description: "Silly hacks you can use in your cakephp applications"
  category:    cakephp
  tags:
    - cakeadvent-2015
    - cakephp
    - api
    - crud
  comments:    true
  sharing:     true
  published:   true
  layout:      post
  series:      CakeAdvent-2015
---

For anyone who has used CakePHP for the past 3 years, this will seem like kicking a dead horse, but here it is. The [CRUD](https://github.com/friendsofcake/crud) plugin is the finest way to rapidly build out apis in CakePHP, and certainly one of the best ways to do so in web application development.

Lets say we were building an api for interacting with a blog. At the very least, we'd need the following controllers:

- Tags
- Categories
- Posts
- Users

You can use cake bake to create/recreate them as many times as you'd like, and you can customize your bake templates to do *exactly* as you need. While this is certainly a fine approach, there are a few issues you'll find with it:

- It is quite destructive to existing code, as it overwrites files.
- All the generated code still needs tests.
- While bake finally supports automatically generating api responses, these responses do not always conform to a "sane" format.
- You are generating hundreds of lines of code which still need to be audited.

## A typical CRUD Application

Here is a CRUD blog plugin I wrote:

```php
<?php
namespace Blog\Controller\Admin;

use Blog\Controller\AppController as BaseController;
use Cake\Event\Event;
use Crud\Controller\ControllerTrait;

class AppController extends BaseController
{
    use ControllerTrait;

    public function initialize()
    {
        parent::initialize();
        $this->loadComponent('RequestHandler');
        $this->loadComponent('Crud.Crud', [
            'actions' => [
                'Crud.Index',
                'Crud.Add',
                'Crud.Edit',
                'Crud.View',
                'Crud.Delete',
            ],
            'listeners' => [
                'Crud.RelatedModels',
                'Crud.Redirect',
            ],
        ]);
    }
}
?>
```

Yes, that's 30 lines of code that sets up all my basic actions, responds with json/xml/whatever I like, with full unit-test coverage. The underlying controllers are relatively simple as well:

```php
<?php
namespace Blog\Controller\Admin;

use Blog\Controller\Admin\AppController;

class PostsController extends AppController
{
}
?>
```

If it feels like cheating, that's because it is. But this isn't an exam, and you have better things to do than worry about the minute details of `public function add`.

## Custom Actions

One complaint about the CRUD plugin is that it seems limited to just CRUD-actions, and doesn't seem to be easy to extend. Both of these are patently false.

The CRUD plugin comes with 5 different base action classes:

- `CreateAction`: Create an entity.
- `DeleteAction`: Delete an entity.
- `EditAction`: Edit a single entity.
- `ViewAction`: View a single entity.
- `IndexAction`: List many entities via pagination.

But we also have 3 special actions for dealing with entities in bulk:

- `BulkDeleteAction`: Delete one or more entities at once
- `BulkSetValueAction`: Set a value for many entities at the same time
- `BulkToggleAction`: Toggle boolean fields for many entities at once

There is even a special action for the [Crud-View](https://github.com/friendsofcake/crud-view) plugin:

- `LookupAction`: Displays a record from a data source for auto-complete purposes.

While the names of these actions is set in stone, it is easy to imagine yourself creating an action for scoping certain fields for editing by a post submitter, and then giving an editor even more control. This is done through the use of custom CakePHP events like so:

```php
public function add()
{
    $this->Crud->on('beforeSave', function(\Cake\Event\Event $event) {
        // do whatever you want with the event->subject and data
    });
    // continue on with the rest of the action
    return $this->Crud->execute();
}
```

The awesome thing about the CRUD plugin is that it is quite easy to create single-purpose actions for your own use. For instance, a recent plugin I was contracted to do has a custom `AutocompleteAction` that integrates with [selectize.js](https://brianreavis.github.io/selectize.js/) to handle tagging. I've also created similar actions for Login/Logout.

## Going Further

While CRUD does simplify a ton of work around creating APIs for applications, many applications *also* need administrative panels for users who don't want to use `curl` to interact with your websites. Thankfully, the [`Crud-View`](https://github.com/friendsofcake/crud-view) plugin is available for just such purposes, and we'll cover it's use tomorrow.

Bonus: Read this lovely tutorial on adding [JWT Auth to a Crud application](http://www.bravo-kernel.com/2015/04/how-to-add-jwt-authentication-to-a-cakephp-3-rest-api/).
