---
  title:       "Generating Administrative Panels with CrudView"
  date:        2015-12-03 13:42
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

Since time immemorial - okay, 2009 - it has been possible to set a custom view for CakePHP applications:

```php
// Don't try this, there isn't an ExcelView in the core :P
$this->viewClass = 'ExcelView';

// Who remembers this?
$this->viewClass = 'MediaView';
```

Since then, the number of view classes has increased dramatically, and we even have ways to map certain types of responses to particular view classes:

```php
$this->RequestHandler->config('viewClassMap', [
    // troll all your xml users
    'xml' => 'Json',
    // this is from a plugin
    'xlsx' => 'CakeExcel.Excel',
    // so is this!
    'csv' => 'CsvView.Csv',
    // we are really into this plugin thing aren't we
    'rss' => 'Feed.Rss'
]);
```

One of the nice things about views is that they completely take over the rendering step, allowing you to create views that automatically generate interactive experiences. Similar to how the Crud plugin allows users to generate api responses, the CrudView plugin allows users to generate administrative panels.

## CrudView

The CrudView plugin is actually one of the more difficult plugins to use, owing to the fact that there is basically zero documentation - we're working on it! It works similar to how the Crud plugin does, using `events` and `config` options to lay everything out *just* right.

To start, you'll want to install the bugger:

```shell
composer require friendsofcake/crud-view:dev-master
```

The simplest method of using CrudView is to configure the Crud `listener` and `viewClass`:


```php
<?php
namespace App\Controller;

use Cake\Controller\Controller;
use Crud\Controller;
use Crud\Controller\ControllerTrait;

class AppController extends Controller
{
    use ControllerTrait;

    public function initialize()
    {
        parent::initialize();

        $this->loadComponent('RequestHandler');
        $this->loadComponent('Flash');

        // setup the viewclass
        $this->viewClass = 'CrudView\View\CrudView';
        $this->loadComponent('Crud.Crud', [
            'actions' => [
                'Crud.Index',
                'Crud.Add',
                'Crud.Edit',
                'Crud.View',
                'Crud.Delete',
            ],
            'listeners' => [
                // and ensure we have the listener configured
                'CrudView.View',
                'Crud.RelatedModels',
                'Crud.Redirect',
            ],
        ]);
    }
}
?>
```

That's it! We now have automatic view scaffolding for every controller that inherits from the `AppController`, *as well as* all the yummy api stuff the Crud plugin gives us by default.

![Crud View Admin](/images/2015/03/admin.png)

### Hiding Sidebar Entries

CrudView is only as smart as you configure it to be. By default, it will show *all* tables in the sidebar and link to their assumed administrative panels. I personally prefer not to show join tables, or anything related to database migrations, and as such my `AppController::beforeFilter` looks something like this:

```php
public function beforeFilter(Event $event)
{
    $this->Crud->action()->config('scaffold.tables_blacklist', [
        'blog_phinxlog',
        'phinxlog',
        'posts_tags',
    ]);

    return parent::beforeFilter($event);
}
```

![Crud View Admin](/images/2015/03/limit-sidebar.png)

### Showing specific fields for specific actions

On my index actions for Categories and Tags, I'd like to hide most fields and just show the `name` field:

```php
public function beforeFilter(Event $event)
    if ($this->request->action == 'index') {
        $this->Crud->action()->config('scaffold.fields', ['name']);
    }
    return parent::beforeFilter($event);
}
```

![Showing specific fields](/images/2015/03/show-specific-fields.png)

> Of note, you can also set these config options in specific actions, the same as you would to customize the crud plugin, but sometimes you can avoid that with very trivial hacks. I wouldn't do the above if there was 10 lines of configuration for the IndexAction, for instance.

### Exposing bulk actions

Sometimes I'd like to expose bulk post actions to my administrative users in a simple to use interface. CrudView takes a tact similar to wordpress and provides a checkboxes next to each row that can be used to "apply" configured actions:

```php
public function initialize()
{
    parent::initialize();
    // map a fiew bulk actions
    $this->Crud->mapAction('deleteAll', 'Crud.Bulk/Delete');
    $this->Crud->mapAction('setStatus', [
        'className' => 'Crud.Bulk/SetValue',
        'field' => 'status',
    ]);
}
public function beforeFilter(Event $event)
{
    // provide the proper links to the actions
    $this->Crud->action()->config('scaffold.bulk_actions', [
        Router::url(['action' => 'deleteAll']) => __('Delete selected'),
        Router::url(['action' => 'setStatus', 'status' => 'published']) => __('Make published'),
        Router::url(['action' => 'setStatus', 'status' => 'pending-review']) => __('Set to pending'),
    ]);
    return parent::beforeFilter($event);
}

public function setStatus()
{
    $this->_statusOptions = [
        'published' => 'Published',
        'pitch' => 'Pitch',
        'assigned' => 'Assigned',
        'in-progress' => 'In Progress',
        'pending-review' => 'Pending Review',
    ];

    $value = $this->request->query('status');
    if (!in_array($value, array_keys($this->_statusOptions))) {
        throw new BadRequestException('No valid status specified');
    }

    // ZHU LI, DO THE THING!
    $this->Crud->action()->config('value', $value);
    return $this->Crud->execute();
}
```

![Showing specific fields](/images/2015/03/bulk-actions.png)

Obviously the logic here can get incredibly complex, and you are welcome to integrate both Crud and CrudView to best express these sorts of experiences for your users.

## You're getting sleepy

Building administrative interfaces isn't the most illustrious job out there, but if you ever find yourself in a pinch, the CrudView plugin is there to help. Hopefully the above will give you enough of a primer to find your way through the plugin, and we'll continue plugging on it until it's both polished and well-documented. Until tomorrow!
