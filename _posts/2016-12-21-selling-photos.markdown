---
  title:       "Selling Photos"
  date:        2016-12-21 17:19
  description: "Part 21 of a series of posts that will help you build out a personal CMS"
  category:    cakephp
  tags:
    - payments
    - stripe
    - cakeadvent-2016
    - cakephp
  comments:    true
  sharing:     true
  published:   true
  layout:      post
  disable_advertisement: true
  series:      CakeAdvent-2016
  og_image:    /images/2016/12/21/sold.png
---

A friend of mine asked for a custom website, so here I am, writing a custom cms. I know, there are plenty of systems out there that would handle his needs, but it's also a good excuse to play around with CakePHP 3, so here we are.

> For the lazy, the codebase we'll be working on will be available on [GitHub](https://github.com/josegonzalez/cakeadvent-2016). I will be pushing each set of changes on the date when each blog post in this series is published. No cheating!

## Errata from previous post

There is a missing commit which removed the `->layout(false)` call in our `UserMailer` class.

Thanks to those who've pointed out my derp. These fixes are available as the first commit in the current release.

## Allowing Paid Photos

Rather than making a whole new post type, we're going to repurpose the existing Photo Post Type. First, lets add a `price` field to our `PhotoPostType::_buildSchema()` method.

```php
$schema->addField('price', ['type' => 'text']);
```

We also want to validate that any prices are positive numbers (we're only allowing whole dollar amounts). I added the following to my `PhotoPostType::_buildValidator()`:

```php
$validator->allowEmpty('price');
$validator->add('price', 'numeric', [
    'rule' => ['naturalNumber', true]
]);
```

Simple enough. We can now add pricing to our photos :)

```shell
git add plugins/PhotoPostType/src/PostType/PhotoPostType.php
git commit -m "Enable photo pricing"
```

## Displaying Checkout Buttons via Stripe

We'll be using Stripe to process payments. Install it via composer:

```shell
composer require stripe/stripe-php
```

In order to simplify our integration, we'll be using their `checkout` product. I created the element `src/Template/Element/stripe.ctp` in order to contain the client-side portion of the integration:

```php
<?php
if (empty($post->get('price'))) {
    return;
}
?>

<div style="text-align:center;">
    <?= $this->Form->create(null, ['class' => 'payment-form', 'url' => ['plugin' => 'PhotoPostType', 'controller' => 'Orders', 'action' => 'order', 'id' => $post->get('id')]]); ?>
        <script
            src="https://checkout.stripe.com/checkout.js" class="stripe-button"
            data-key="<?= \Cake\Core\Configure::read('Stripe.publishablekey') ?>"
            data-amount="<?= $post->getPriceInCents() ?>"
            data-name="<?= \Cake\Core\Configure::read('App.name') ?>"
            data-description="<?= $post->get('title') ?>"
            data-image="https://stripe.com/img/documentation/checkout/marketplace.png"
            data-locale="auto"
            data-zip-code="true"
            data-billing-address="true"
            data-shipping-address="true"
            data-label="Buy this photo">
          </script>
    <?= $this->Form->end(); ?>
</div>
```

The above form uses the converted `PostType` object to configure the button. We'll need two new environment variables though, which you can retrieve from your stripe dashboard:

```shell
export STRIPE_PUBLISHABLEKEY=pk_test_1234
export STRIPE_SECRETKEY=sk_test_abcd
```

You can include this element in your `photo-view.ctp` files like so:

```php
<?= $this->element('stripe', ['post' => $post]); ?>
```

One tricky thing about stripe is that the amount it accepts is a number in cents, not whole dollars, so we need to add the following to our `PhotoPostType` class to make the conversion:

```php
public function getPriceInCents()
{
    $price = $this->get('price');
    if (empty($price)) {
        return 0;
    }

    return $price * 100;
}
```

This takes care of most of the user-facing integration, so we'll save our work for now:

```shell
git add composer.json composer.lock config/.env.default plugins/DefaultTheme/src/Template/Element/post_type/photo-view.ctp plugins/PhotoPostType/src/PostType/PhotoPostType.php plugins/PhotoPostType/src/Template/Element/post_type/photo-view.ctp src/Template/Element/stripe.ctp
git commit -m "Implement user-facing portion of stripe integration"
```

## Processing Payments

We'll be storing order information in a new table. This is the migration I generated:

```shell
bin/cake bake migration --plugin PhotoPostType create_orders charge_id email shipping_name shipping_address_line_1 shipping_address_zip shipping_address_state shipping_address_city shipping_address_country shipped:boolean created modified
```

I had to modify the default for `shipped` to be `false` in the generated migration file. We can now run it:

```shell
bin/cake migrations migrate --plugin PhotoPostType
```

Since I want composer to run this automatically when the application is "compiled", I added the following to `scripts.compile` in my `composer.json` file:

```json
"bin/cake migrations migrate -p PhotoPostType"
```

Now we can generate tables for this:

```shell
bin/cake bake model Orders --plugin PhotoPostType
```

On the server-side, we'll need an `OrdersController::order()` action to handle the actual payments. Here is the initial scaffolding for that:

```php
<?php
namespace PhotoPostType\Controller;

use Cake\Core\Configure;
use PhotoPostType\Controller\AppController;
use Stripe\Error\Card as CardError;
use Stripe\Charge;
use Stripe\Customer;
use Stripe\Stripe;

class OrdersController extends AppController
{
    /**
     * Initialization hook method.
     *
     * Use this method to add common initialization code like loading components.
     *
     * e.g. `$this->loadComponent('Security');`
     *
     * @return void
     */
    public function initialize()
    {
        parent::initialize();
        $this->Auth->allow('order');
    }

    /**
     * Order action
     *
     * @return void
     */
    public function order()
    {
        $this->loadModel('Posts');
        $post = $this->Posts->find()
                           ->where(['id' => $this->request->query('id')])
                           ->contain('PostAttributes')
                           ->first()
                           ->getPostType();

        $charge = $this->chargeCard($post->getPriceInCents());
        if (empty($charge)) {
            $this->Flash->error(__('Your card was declined'));
            return $this->redirect($this->referer('/', true));
        }

        $this->createOrder($charge);
        $this->Flash->success(__('Order placed! Check your email for more details :)'));
        return $this->redirect($this->referer('/', true));
    }
}
```

A few notes:

- I'm allowing the `order` action. This is necessary as we have default denied requests to all actions in our `AppController`.
- We need to retrieve the post being requested as a post-type, hence the find at the beginning.
- There isn't too much error handling, but you can expand this to suit your needs.
- This should be refactored as a custom Form class, but it's here because I am lazy.

Here is the contents of my `OrdersController::chargeCard()` method:

```php
/**
 * Order action
 *
 * @return null|\Stripe\Charge
 */
protected function chargeCard($amount)
{
    Stripe::setApiKey(Configure::read('Stripe.secretkey'));
    try {
        $customer = Customer::create(array(
            'email' => $this->request->data('stripeEmail'),
            'card'  => $this->request->data('stripeToken')
        ));
        return Charge::create(array(
            'customer' => $customer->id,
            'amount'   => $amount,
            'currency' => 'usd'
        ));
    } catch (CardError $e) {
        $this->log($e);
        return null;
    }
}
```

Pretty straightforward. We need to create a customer in stripe and then charge the card. If we get any card authentication errors, we log it for inspection and don't return the charge. My `OrdersController::createOrder()` method is as follows:

```php
/**
 * Order action
 *
 * @return null|\Stripe\Charge
 */
protected function createOrder($charge)
{
    $data = [
        'chargeid' => $charge->id,
        'email' => $this->request->data('stripeEmail'),
        'shipping_name' => $this->request->data('stripeShippingName'),
        'shipping_address_line_1' => $this->request->data('stripeShippingAddressLine1'),
        'shipping_address_zip' => $this->request->data('stripeShippingAddressZip'),
        'shipping_address_state' => $this->request->data('stripeShippingAddressState'),
        'shipping_address_city' => $this->request->data('stripeShippingAddressCity'),
        'shipping_address_country' => $this->request->data('stripeShippingAddressCountry'),
        'shipped' => false,
    ];

    $order = $this->Orders->newEntity($data);
    if (!$this->Orders->save($order)) {
        $this->log($order->errors());
    }
}
```

We're just taking the charge and the submitted data and saving it as an order.

Now we need to enable routing for this controller action. I created the `plugins/PhotoPostType/config/routes.php` with the following contents:

```php
<?php
use Cake\Core\Configure;
use Cake\Routing\Router;
use Cake\Routing\Route\DashedRoute;

$routeClass = Configure::read('PhotoPostType.Routes.routeClass');
$routeClass = $routeClass ?: DashedRoute::class;

$photoPostTypePrefix = Configure::read('PhotoPostType.Routes.prefix');
$photoPostTypePrefix = $photoPostTypePrefix ?: '/order';
$photoPostTypePrefix = '/' . trim($photoPostTypePrefix, "\t\n\r\0\x0B/");
Router::plugin('PhotoPostType', ['path' => $photoPostTypePrefix], function ($routes) use ($routeClass) {
    $routes->connect(
        '/',
        ['controller' => 'Orders', 'action' => 'order'],
        ['id' => '\d+', 'pass' => ['id'], 'routeClass' => $routeClass]
    );
});
```

We also need to load the routes for this plugin in our `config/bootstrap.php`. Replace the line loading the `PhotoPostType` plugin with the following:

```php
Plugin::load('PhotoPostType', ['bootstrap' => true, 'routes' => true]);
```

Lastly, I added a bit of css to `plugins/DefaultTheme/webroot/css/style.css` to show off our flash styling.

```css
.message {
    text-align: center;
}
.message.success {
    background-color: lightgreen;
}
.message.error {
    background-color: #D33C44;
}
```

Now you can try it out on any user-facing post page. You should get a message like the following:

![awh yis](/images/2016/12/21/sold.png)

Commit your changes :)

```shell
git add composer.json config/bootstrap.php plugins/DefaultTheme/webroot/css/style.css plugins/PhotoPostType/config/Migrations/20161222013607_CreateOrders.php plugins/PhotoPostType/config/routes.php plugins/PhotoPostType/src/Controller/OrdersController.php plugins/PhotoPostType/src/Model/Entity/Order.php plugins/PhotoPostType/src/Model/Table/OrdersTable.php plugins/PhotoPostType/tests/Fixture/OrdersFixture.php plugins/PhotoPostType/tests/TestCase/Model/Table/OrdersTableTest.php
git commit -m "Implement payment processing"
```

---

> For those that may just want to ensure their codebase matches what has been done so far, the codebase is available on GitHub and tagged as [0.0.21](https://github.com/josegonzalez/cakeadvent-2016/tree/0.0.21).

Our CMS is pretty complete. We've got a few odds and ends to tie up - like showing off orders in the admin and notifying users of their order and when it's shipped - but we're done for today.

Be sure to follow along via twitter on [@savant](https://twitter.com/savant). If you'd like to subscribe to this blog, you may follow the [rss feed here](/atom.xml). Also, all posts in the series will be conveniently linked on the sidebar of every post in the 2016 CakeAdvent Calendar. Come back tomorrow for more delicious content.
