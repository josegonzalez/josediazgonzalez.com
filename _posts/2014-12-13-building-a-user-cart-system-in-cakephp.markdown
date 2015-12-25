---
  title:       "Building a user cart system in CakePHP"
  date:        2014-12-13 17:26
  description: "Part 4 of 7 in a series of posts designed to teach you how to use CakePHP 3 effectively"
  category:    cakephp
  tags:
    - cakeadvent-2014
    - cakephp
    - composer
    - cart management
  comments:    true
  sharing:     true
  published:   true
  layout:      post
  series:      CakeAdvent-2014
---

Today’s post will be fairly straightforward. We should now have dummy data in our application, can browse products, and authenticate as users to actually start using our store. So lets allow people to add items to their carts.

First thing we’ll need is to customize the methods available to the Products controller. We already have a bake event in our `app/config/bootstrap_cli.php`, so we’ll add the following bit of code to limit the actions (as well as add two new ones);

```php
if ($isController && $name == 'Products') {
    $view->viewVars['actions'] = ['index', 'view', 'add', 'addToCart', 'removeFromCart'];
}
```

Next, we’ll create two new bake controller elements in our `src/Template/Bake/Element/Controller` directory. One will be our `addToCart.ctp` file, and the other will be `removeFromCart.ctp`. This is our `addToCart.ctp`:

```
/**
 * Add to cart method
 *
 * @param string|null $id <%= $singularHumanName %> id
 * @return void
 * @throws \Cake\Network\Exception\NotFoundException
 */
    public function addToCart($id = null) {
        $<%= $singularName%> = $this-><%= $currentModelName %>->get($id);
        $event = new \Cake\Event\Event('Order.addToCart', $this, [
            '<%= $singularName%>' => $<%= $singularName%>,
            'user' => $this->Auth->user(),
        ]);
        \Cake\Event\EventManager::instance()->dispatch($event);
        if ($event->result) {
            $this->Flash->success('The <%= $singularName%> has been added to your cart.');
        } else {
            $this->Flash->error('The <%= $singularName%> could not be added to your cart.');
        }
        return $this->redirect($this->referer());
    }
```

And here is our `removeFromCart.ctp`:

```
/**
 * Remove from cart method
 *
 * @param string|null $id <%= $singularHumanName %> id
 * @return void
 * @throws \Cake\Network\Exception\NotFoundException
 */
    public function removeFromCart($id = null) {
        $<%= $singularName%> = $this-><%= $currentModelName %>->get($id);
        $event = new \Cake\Event\Event('Order.removeFromCart', $this, [
            '<%= $singularName%>' => $<%= $singularName%>,
            'user' => $this->Auth->user(),
        ]);
        \Cake\Event\EventManager::instance()->dispatch($event);
        if ($event->result) {
            $this->Flash->success('The <%= $singularName%> has been removed from your cart.');
        } else {
            $this->Flash->error('The <%= $singularName%> could not be removed from your cart.');
        }
        return $this->redirect($this->referer());
    }
```

A few notes:

- We’re using events to add and remove items from our cart. Some people would call table/entity methods directly, but we’re doing this to keep our actions flexible.
- We use the `Table::get()` method which may return a `NotFoundException`. If a user tries to add an invalid product to their cart, we should signal such using the Application’s configured Error Handler.
- We aren’t handling adding multiple of the same product to our cart just yet. If you’d like to, please modify your templates, but we’re keeping our cart simple.

We now need to add one of these actions to our `/products/index` page. We’ll need to first copy over the core `index.ctp` so we can modify it a bit:

```shell
TEMPLATE_DIR="src/Template/Bake/"
BAKE_TEMPLATE_DIR="vendor/cakephp/cakephp/src/Template/Bake/"
cd /vagrant/app
cp $BAKE_TEMPLATE_DIR/Template/index.ctp $TEMPLATE_DIR/Template/index.ctp
```

Our new `src/Template/Bake/Template/index.ctp` does not take a list of related actions to perform on an item, so we’re going to add this. Around line 86, you’ll see a chunk of code that looks like the following:

```
<td class="actions">
    <?= $this->Html->link(__('View'), ['action' => 'view', <%= $pk %>]) ?>
    <?= $this->Html->link(__('Edit'), ['action' => 'edit', <%= $pk %>]) ?>
    <?= $this->Form->postLink(__('Delete'), ['action' => 'delete', <%= $pk %>], ['confirm' => __('Are you sure you want to delete # {0}?', <%= $pk %>)]) ?>
</td>
```

We’re going to replace it with the following:


```
<td class="actions">
    <% foreach ($singularActions as $config) : %>
        <?= $this->Html->link(__('<%= $config['title'] %>'), ['action' => '<%= $config['action'] %>', <%= $pk %>]) ?>
    <% endforeach; %>
    <% foreach ($singularConfirmActions as $config) : %>
        <?= $this->Form->postLink(__('<%= $config['title'] %>'), ['action' => '<%= $config['action'] %>', <%= $pk %>], ['confirm' => __('<%= $config['message'] %>', <%= $pk %>)) ?>
    <% endforeach; %>
</td>
```

In the modified template, we’re removing the hardcoded list of actions displayed and introducing two new variables, `singularActions` and `singularConfirmActions`. These will act upon a single item listed on the index page. We’ll configure them in our `app/config/bootstrap_cli.php` with the following new event:

```php
EventManager::instance()->attach(function (Event $event) {
    $view = $event->subject;
    $name = Hash::get($view->viewVars, 'pluralHumanName');
    $isIndexView = strpos($event->data[0], 'Bake/Template/index.ctp') !== false;
    if ($isIndexView) {
        $singularActions = [
            ['action' => 'view', 'title' => 'View'],
            ['action' => 'edit', 'title' => 'Edit'],
        ];
        $singularConfirmActions = [
            ['action' => 'delete', 'title' => 'Delete', 'message' => 'Are you sure you want to delete # {0}?'],
        ];
        if ($name == 'Products') {
            $singularActions = [
                ['action' => 'view', 'title' => 'View'],
                ['action' => 'addToCart', 'title' => 'Add To Cart'],
            ];
            $singularConfirmActions = [];
        }
        $view->viewVars['singularActions'] = $singularActions;
        $view->viewVars['singularConfirmActions'] = $singularConfirmActions;
    }
}, 'Bake.beforeRender');
```

The above event will allow us to keep all other baked `index.ctp` template output the same, while allowing us to hijack the actions listed for the `Products` view to show our `Add To Cart` link.

Finally, we will need to actually handle processing of our events. We’ll create an `app/config/events.php` and include it on our `app/config/bootstrap.php` like so:

```php
require __DIR__ . '/events.php';
```

We need two events, one to manage adding a product to the user’s cart, and one to manage removing the product from a user’s cart. We’ll have the user’s session at hand, as well as the product entity. Here is what our `Order.addToCart` event will look like:

```php
EventManager::instance()->attach(function (Event $event) {
    $data = $event->data;
    if (empty($data['user'])) {
        // User is not logged in
        return $event->result = false;
    }
    if (empty($data['product'])) {
        // Invalid product specified
        return $event->result = false;
    }
    $user = $data['user'];
    $product = $data['product'];
    if ($product->stock <= 0) {
        // No more stock for product
        return $event->result = false;
    }
    $Orders = TableRegistry::get('Orders');
    $order = $Orders->find()
                    ->where(['user_id' => $user['id']])
                    ->first();
    if (empty($order)) {
        // Create a new order where necessary
        $order = $Orders->newEntity(['user_id' => $user['id']]);
        $order = $Orders->save($order);
    }
    $OrderItems = TableRegistry::get('OrderItems');
    $orderItem = $OrderItems->newEntity([
        'order_id' => $order->id,
        'product_id' => $product->id,
        'quantity' => 1,
        'price' => $product->price,
    ]);
    // Save the order item entry
    if (!$OrderItems->save($orderItem)) {
        return $event->result = false;
    }
    // Decrease the amount of stock
    $Products = TableRegistry::get('Products');
    $product->stock--;
    return $event->result = !!$Products->save($product);
}, 'Order.addToCart');
```

And our equally-well commented `Order.removeFromCart` event:

```php
EventManager::instance()->attach(function (Event $event) {
    $data = $event->data;
    if (empty($data['user'])) {
        // User is not logged in
        return $event->result = false;
    }
    if (empty($data['product'])) {
        // Invalid product specified
        return $event->result = false;
    }
    $user = $data['user'];
    $product = $data['product'];
    $Orders = TableRegistry::get('Orders');
    $order = $Orders->find()
                    ->where(['user_id' => $user['id']])
                    ->first();
    if (empty($order)) {
        // There is no cart associated with the user
        return $event->result = false;
    }
    $OrderItems = TableRegistry::get('OrderItems');
    $orderItem = $OrderItems->find()
                            ->where(['order_id' => $order->id, 'product_id' => $product->id])
                            ->first();
    if (empty($orderItem)) {
        // Item not in user's cart
        return $event->result = false;
    }
    if (!$OrderItems->delete($orderItem)) {
        // Unable to remove item from cart
        return $event->result = false;
    }
    // Increase product stock
    $Products = TableRegistry::get('Products');
    $product->stock++;
    return $event->result = !!$Products->save($product);
}, 'Order.removeFromCart');
```

> A real ecommerce solution will have much more stringent protocols surrounding adding/removing stock from a product. We’re doing it this way because it’s much simpler than going through the rabbit-hole, but please keep this in mind if you are building out your own solution for a customer. For instance, consider doing all table manipulation using a transaction.

One last thing. We’ll want a new action to list all the items in a user’s order, as well as a way to actually call our `/products/removeFromCart` action. We’ll define a new Controller bake template in `src/Template/Bake/Element/Controller/cart.ctp`.

```
/**
 * Cart method
 *
 * @return void
 */
    public function cart() {
        $user_id = $this->Auth->user('id');
        $<%= $singularName%> = $this-><%= $currentModelName %>->find()
                        ->where(['user_id' => $user_id])
                        ->first();
        if (empty($<%= $singularName%>)) {
            $<%= $singularName%> = $this-><%= $currentModelName %>->newEntity(['user_id' => $user_id]);
            $<%= $singularName%> = $this-><%= $currentModelName %>->save($<%= $singularName%>);
        }
        $items = $this-><%= $currentModelName %>->OrderItems->find()
                                  ->where(['order_id' => $<%= $singularName%>->id])
                                  ->contain(['Products'])
                                  ->all();
        $this->set(compact('<%= $singularName%>', 'items'));
    }
```

And we’ll restrict our `Orders` controller to just this action in our `app/config/bootstrap_cli.php` with the following check:

```php
if ($isController && $name == 'Orders') {
    $view->viewVars['actions'] = ['cart'];
}
```

And our simple `src/Template/Bake/Template/cart.ctp` will be the following:

```
<div class="orders index large-10 medium-9 columns">
    <table cellpadding="0" cellspacing="0">
        <thead>
            <tr>
                <th>Name</th>
                <th>Quantity</th>
                <th>Price</th>
                <th>Actions</th>
            </tr>
        </thead>
        <tbody>
            <?php foreach ($items as $item) : ?>
            <tr>
                <td><?= $item->product->name ?></td>
                <td><?= $item->quantity ?></td>
                <td><?= $item->price ?></td>
                <td>
                    <?= $this->Html->link(__('View'), ['controller' => 'Products', 'action' => 'view', $item->product_id]) ?>
                    <?= $this->Html->link(__('Remove from Cart'), ['controller' => 'Products', 'action' => 'removeFromCart', $item->product_id]) ?>
                </td>
            </tr>
            <?php endforeach; ?>
        </tbody>
    </table>
</div>
```

We can *now* run bake to recreate the respective controllers and templates and we should have a reasonable cart system!

```shell
cd /vagrant/app
bin/cake bake controller orders -f
bin/cake bake controller products -f
bin/cake bake view orders -f
bin/cake bake view products -f
```

You can access your cart by going to `/orders/cart`.

## Homework Time

Your homework today is as follows:

- Remove all those extra pesky actions on the index page
- Add a button to add products to your cart from the product view page
- Link to the cart in your header (checkout your `src/Template/Layout/default.ctp`)
- Add a custom route for `/orders/cart` to be `/cart`
- Add a `total` to your cart page.
- Require that user’s be authenticated before adding/removing/viewing their cart

Be sure to follow along via twitter on [@savant](https://twitter.com/savant). If you’d like to subscribe to this blog, you may follow the [rss feed here](/atom.xml). Also, all posts in the series will be conveniently linked on the sidebar of every post in the 2014 CakeAdvent Calendar. Come back tomorrow for more delicious content.


