---
  title:       "Handling Photo Orders"
  date:        2016-12-22 08:53
  description: "Part 22 of a series of posts that will help you build out a personal CMS"
  category:    cakephp
  tags:
    - crud-view
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

## Routing the orders admin panel

Before we can get to configuring our admin panel, we'll need to be able to route it. For our `PhotoPostType`, we've hardcoded just a single route for viewing an order, but we want to now also properly route admin requests. Here is what I've modified the `plugins/PhotoPostType/config/routes.php` to:

```php
<?php
use Cake\Core\Configure;
use Cake\Routing\RouteBuilder;
use Cake\Routing\Router;
use Cake\Routing\Route\DashedRoute;

$routeClass = Configure::read('PhotoPostType.Routes.routeClass');
$routeClass = $routeClass ?: DashedRoute::class;

Router::plugin('PhotoPostType', ['path' => '/'], function ($routes) use ($routeClass) {
    $photoPostTypePrefix = Configure::read('PhotoPostType.Routes.prefix');
    $photoPostTypePrefix = $photoPostTypePrefix ?: '/order';
    $photoPostTypePrefix = '/' . trim($photoPostTypePrefix, "\t\n\r\0\x0B/");

    $routes->connect(
        $photoPostTypePrefix,
        ['controller' => 'Orders', 'action' => 'order'],
        ['id' => '\d+', 'pass' => ['id'], 'routeClass' => $routeClass]
    );
    $routes->scope('/admin/orders', ['controller' => 'Orders'], function (RouteBuilder $routes) {
          $routes->connect('/', ['action' => 'index']);
          $routes->fallbacks();
    });
});
```

I'm now mounting the plugin under `/` and also scoping `/admin/orders` to our `PhotoPostType.OrdersController`. One other small change we'll need to do is modify our `AppController::getUtilityNavigation()` method to scope all existing navigation elements to `plugin => null`. I've also added a single extra navigation element for logged in users:

```php
new \CrudView\Menu\MenuItem(
    'Orders',
    ['plugin' => 'PhotoPostType', 'controller' => 'Orders', 'action' => 'index']
),
```

Not the nicest thing in the world, as now we're crossing boundaries between plugins and the application, but this will do for now. We could alternatively use an event and bind to that event in `plugins/PhotoPostType/config/bootstrap.php`, but that seems like more trouble than it's worth for now.

Save your work:

```shell
git add plugins/PhotoPostType/config/routes.php src/Controller/AppController.php
git commit -m "Route and link to OrdersController admin actions"
```

## Enabling CrudView for the OrdersController

This is relatively simple. Since our `OrdersController` eventually inherits from the `AppController`, all we need to do is enable crud-view and allow access to it. I added the following property to my `OrdersController`:

```php
/**
 * A list of actions where the CrudView.View
 * listener should be enabled. If an action is
 * in this list but `isAdmin` is false, the
 * action will still be rendered via CrudView.View
 *
 * @var array
 */
protected $adminActions = ['index', 'delete'];
```

And next I've added the following `OrdersController::isAuthorized()` method:

```php
/**
 * Check if the provided user is authorized for the request.
 *
 * @param array|\ArrayAccess|null $user The user to check the authorization of.
 *   If empty the user fetched from storage will be used.
 * @return bool True if $user is authorized, otherwise false
 */
public function isAuthorized($user = null)
{
    $action = $this->request->param('action');
    if (in_array($action, $this->adminActions)) {
        return true;
    }
    return parent::isAuthorized($user);
}
```

This should allow me access to the `OrdersController`, which we will be shortly customizing via an `OrdersListener` located in `plugins/PhotoPostType/src/Listener/OrdersListener.php`. I'm going to bind that in our `OrdersController::initialize()` method:

```php
$this->Crud->addListener('Orders', 'PhotoPostType\Listener\OrdersListener');
```

And here is the skeleton for that class:

```php
<?php
namespace PhotoPostType\Listener;

use Cake\Event\Event;
use Crud\Listener\BaseListener;

/**
 * Orders Listener
 */
class OrdersListener extends BaseListener
{
    /**
     * Callbacks definition
     *
     * @return array
     */
    public function implementedEvents()
    {
        return [
            'Crud.beforeHandle' => 'beforeHandle',
        ];
    }

    /**
     * Before Handle
     *
     * @param \Cake\Event\Event $event Event
     * @return void
     */
    public function beforeHandle(Event $event)
    {
    }
}
```

I'm going to save my state before I get too carried away

```shell
git add plugins/PhotoPostType/src/Controller/OrdersController.php plugins/PhotoPostType/src/Listener/OrdersListener.php
git commit -m "Enable CrudView for the OrdersController"
```

## Customizing our index page

Our index page is a bit special. Here is what I want to do:

- Disable non-CrudView actions
- Show a link to the `charge_id` on stripe
- Show a single, unified element for the contact information

For the first item, we'll want to add the following to our `OrdersController::initialize()` method.

```php
$this->Crud->config('actions.add', null);
$this->Crud->config('actions.edit', null);
$this->Crud->config('actions.view', null);
```

This completely disables the actions, while also ensuring that we don't show any references to them in CrudView.

Next, we'll need to add the following to our `OrdersListener::beforeHandle()`:

```php
if ($event->subject->action === 'index') {
    $this->beforeHandleIndex($event);

    return;
}
```

And the corresponding `OrdersListener::beforeHandleIndex()` is as follows:

```php
/**
 * Before Handle Index Action
 *
 * @param \Cake\Event\Event $event Event
 * @return void
 */
public function beforeHandleIndex(Event $event)
{
    $this->_action()->config('scaffold.fields', [
        'id',
        'chargeid' => [
            'formatter' => 'element',
            'element' => 'PhotoPostType.crud-view/index-chargeid',
        ],
        'contact' => [
            'formatter' => 'element',
            'element' => 'PhotoPostType.crud-view/index-contact',
        ],
        'shipped' => [
        ],
        'created' => [
        ],
    ]);
}
```

Previously, we used an inline anonymous function to format the page. This works okay, but in this case we're going to be doing a bit more work, so using an element seems more appropriate. Here is the contents of my `plugins/PhotoPostType/src/Template/Element/crud-view/index-contact.ctp` template:

```php
<?= implode("<br>", array_filter([
    $context->get('shipping_name'),
    $context->get('shipping_address_line_1'),
    sprintf(
        '%s, %s %s',
        $context->get('shipping_address_city'),
        $context->get('shipping_address_state'),
        $context->get('shipping_address_zip')
    ),
    $context->get('shipping_address_country'),
    $context->get('email'),
]));
```

Pretty straightforward. I'm basically getting all the contact info and splatting it together in one element. The `$context` object is simply a reference to the entity being displayed.

Our `plugins/PhotoPostType/src/Template/Element/crud-view/index-contact.ctp` template is a bit more complex:

```php
<?php
use Cake\Core\Configure;

$mode = Configure::read('Stripe.mode');
if ($mode === 'live') {
    echo $this->Html->link($value, sprintf('https://dashboard.stripe.com/payments/'. $value));
} else {
    echo $this->Html->link($value, sprintf('https://dashboard.stripe.com/test/payments/'. $value));
}
```

Depending upon the stripe mode, we link to either the live or the test payment. I've also added the following to my `config/.env.default` (and equivalent to `config/.env`) to handle that new `Configure` value.

```shell
export STRIPE_MODE=test
```

Assuming everything was configured properly, here is what that will look like:

![dashboard confessional](/images/2016/12/22/dashboard.png)

I'll save my changes here.

```shell
git add config/.env.default plugins/PhotoPostType/src/Controller/OrdersController.php plugins/PhotoPostType/src/Listener/OrdersListener.php plugins/PhotoPostType/src/Template/Element/crud-view/index-chargeid.ctp plugins/PhotoPostType/src/Template/Element/crud-view/index-contact.ctp
git commit -m "Customize the OrdersController::index() action"
```

## Adding bulk actions

Now that we have a custom admin panel, we'll need to be able to mark things as shipped. We'll be using the `Crud.Bulk/SetValue` action class, which allows us to bulk update records and set a specific value. First, lets map the action in the `OrdersController::initialize()` method:

```php
$this->Crud->mapAction('setShipped', [
    'className' => 'Crud.Bulk/SetValue',
    'field' => 'shipped',
]);
```

We also need to add it to the list of allowed admin actions:

```php
/**
 * A list of actions where the CrudView.View
 * listener should be enabled. If an action is
 * in this list but `isAdmin` is false, the
 * action will still be rendered via CrudView.View
 *
 * @var array
 */
protected $adminActions = ['index', 'delete', 'setShipped'];
```

Finally, we'll want to configure the action itself. I'd like to be able to set the value as 0 or 1 (mapping to true or false in our database). I also need to properly configure the status message. Start by adding the following to `OrdersListener::beforeHandle()`:

```php
if ($event->subject->action === 'setShipped') {
    $this->beforeHandleSetShipped($event);

    return;
}
```

And the `OrdersListener::beforeHandleSetShipped()` method is as follows:

```php
/**
 * Before Handle SetShipped Action
 *
 * @param \Cake\Event\Event $event Event
 * @return void
 */
public function beforeHandleSetShipped(Event $event)
{
    $value = (int)$this->_request()->query('shipped');
    if ($value !== 0 && $value !== 1) {
        throw new BadRequestException('Invalid ship status specified');
    }

    $verb = 'shipped';
    if ($value === 0) {
        $verb = 'unshipped';
    }

    $this->_action()->config('value', $value);
    $this->_action()->config('messages.success.text', sprintf('Marked orders as %s!', $verb));
    $this->_action()->config('messages.error.text', sprintf('Could not mark orders as %s!', $verb));
}
```

Lastly, we need to actually link to the bulk actions. You can configure this by adding the next 4 lines to your `OrdersListener::beforeHandleIndex()`:

```php
$this->_action()->config('scaffold.bulk_actions', [
    Router::url(['action' => 'setShipped', 'shipped' => '1']) => __('Mark as shipped'),
    Router::url(['action' => 'setShipped', 'shipped' => '0']) => __('Mark as unshipped'),
]);
```

![bulk dashboard confessional](/images/2016/12/22/dashboard-bulk.png)


And we're done!

```shell
git add plugins/PhotoPostType/src/Controller/OrdersController.php plugins/PhotoPostType/src/Listener/OrdersListener.php
git commit -m "Add bulk actions for modifying shipping status"
```

---

> For those that may just want to ensure their codebase matches what has been done so far, the codebase is available on GitHub and tagged as [0.0.22](https://github.com/josegonzalez/cakeadvent-2016/tree/0.0.22).

We're nearing the finish line. The only major items include notifying the primary user when a new order has come in, as well as notifying users when their items have been shipped. We could certainly add a contact form or about page to the frontend as well, though those can be homework exercises for you :)

Be sure to follow along via twitter on [@savant](https://twitter.com/savant). If you'd like to subscribe to this blog, you may follow the [rss feed here](/atom.xml). Also, all posts in the series will be conveniently linked on the sidebar of every post in the 2016 CakeAdvent Calendar. Come back tomorrow for more delicious content.
