---
  title:       "Processing Payments with CakePHP 3 and Omnipay"
  date:        2014-12-14 17:26
  description: "Part 5 of 7 in a series of posts designed to teach you how to use CakePHP 3 effectively"
  category:    CakePHP
  tags:
    - cakeadvent-2014
    - cakephp
    - composer
    - payments
    - stripe
  comments:    true
  sharing:     true
  published:   true
  layout:      post
  series:      CakeAdvent-2014
---

Today we’ll actually process a charge from our user - because making money is nice.

As good PHP citizens, the CakePHP community does not re-implement existing libraries in the 3.x release - CakeTime with Carbon and the Migrations plugin with Phinx are good examples.

Given the CakePHP philosophy, we’ll use the Omnipay library. Omnipay provides a single interface for each payment processor, allowing developers to create a process that works best for their developers.

First, you’ll want to install Omnipay. We’ll be using stripe to process transactions, so install the omnipay adapter for that as well:

```shell
composer require omnipay/omnipay
composer require omnipay/stripe
```

We need to also configure our stripe integration in our `app/config/app.php` file. We’ll simply add our Stripe’s `api_key` - found [here](https://dashboard.stripe.com/account/apikeys) - as so to the array:

```php
    'Stripe' => [
        // using the test keyS for now
        'secret_key' => 'sk_test_SOME_KEY',
        'publishable_key' => 'pk_test_SOME_KEY',
    ],
```

Next, we’ll create a new action in our `orders` page called `checkout`. We’ll use bake again so that we can continue to add new actions without modifying the files themselves. Here is what our action - located in `src/Template/Bake/Element/Controller/checkout.ctp` - will look like (see inline comments for details):

```
/**
 * Checkout method
 *
 * @return void
 */
    public function checkout() {
        // Find the existing order
        $user_id = $this->Auth->user('id');
        $order = $this->Orders->find()
                        ->where(['user_id' => $user_id])
                        ->contain(['OrderItems'])
                        ->first();
        // Redirect back to the cart if there is no order or any order items
        if (empty($order) || empty($order->order_items)) {
            $this->Flash->error(__('No items in cart'));
            return $this->redirect(['action' => 'cart']);
        }
        $amount = array_reduce($order->order_items, function ($carry, $item) {
            return $carry + $item->price;
        }, 0);
        $this->set(compact('order', 'amount'));
        if (!$this->request->is('post')) {
            return;
        }
        // Create an Omnipay Stripe gateway object and configure it
        $gateway = \Omnipay\Omnipay::create('Stripe');
        $gateway->setApiKey(\Cake\Core\Configure::read('Stripe.secret_key'));
        // Create a purchase with the stripe token and the amount in the cart
        $response = $gateway->purchase([
            'amount' => $amount,
            'currency' => 'USD',
            'token' => $this->request->data('Order.stripeToken')
        ])->send();
        // Check to see if the purchase was successful
        if ($response->isSuccessful()) {
            // Do something with the data
            \Cake\Log\Log::debug(json_encode($response->getData()));
            $this->Flash->error(__('Payment successful!'));
            return $this->redirect(['action' => 'cart']);
        } else {
            $this->Flash->error(__('Error processing payment: {0}', $response->getMessage()));
        }
    }
```

And this will be our `src/Template/Bake/Template/checkout.ctp` file. It’s a bit long, but basically it allows a user to submit a credit card to stripe without touching your servers, and then subsequently submits a token to your app that you can use to actually process a payment:

```php
<div class="<%= $pluralVar %> form">
<?= $this->Form->create(null, ['class' => 'payment-form']); ?>
    <fieldset>
        <legend><?= __('Enter your details to submit the order ({0} total)', $amount) ?></legend>
        <span class="payment-errors"></span>
        <?= $this->Form->input('Order.number', ['label' => 'Card Number']); ?>
        <?= $this->Form->input('Order.cvc', ['label' => 'CVC']); ?>
        <?= $this->Form->input('Order.exp-month', ['label' => 'Expiration Month (MM)']); ?>
        <?= $this->Form->input('Order.exp-year', ['label' => 'Expiration Year (YYYY)']); ?>
    </fieldset>
    <?= $this->Form->button(__('Submit Order')); ?>
<?= $this->Form->end(); ?>
</div>
<script type="text/javascript" src="http://code.jquery.com/jquery-1.10.2.js"></script>
<script type="text/javascript" src="https://js.stripe.com/v2/"></script>
<script type="text/javascript">
// The JS needs access to the publishable stripe key
Stripe.setPublishableKey('<?php echo \Cake\Core\Configure::read('Stripe.publishable_key'); ?>');
// We need to create a callback to process the stripe payement, as
// well as show errors or submit the token in case of success.
var stripeResponseHandler = function(status, response) {
  var $form = $('.payment-form');
  if (response.error) {
    // Show the errors on the form
    $form.find('.payment-errors').text(response.error.message);
    $form.find('button').prop('disabled', false);
  } else {
    // token contains id, last4, and card type
    var token = response.id;
    // Reset form data we do not want to submit to the server
    $('#order-number, #order-cvc, #order-exp-month, #order-xp-year').val("");
    // Insert the token into the form so it gets submitted to the server
    $form.append($('<input type="hidden" name="Order[stripeToken]" />').val(token));
    // and submit
    $form.get(0).submit();
  }
};
jQuery(function($) {
  $('.payment-form').submit(function(e) {
    // Prevent the form from submitting with the default action
    e.preventDefault();
    var $form = $(this);
    // Disable the submit button to prevent repeated clicks
    $form.find('button').prop('disabled', true);
    Stripe.card.createToken({
      number: $('#order-number').val(),
      cvc: $('#order-cvc').val(),
      exp_month: $('#order-exp-month').val(),
      exp_year: $('#order-exp-year').val()
    }, stripeResponseHandler);
  });
});
</script>
```

Now we need to tell bake to create these this action and it’s related template in our `app/config/bootstrap_cli.php`. The actions for the `Orders` controller should look something like the following:

```php
if ($isController && $name == 'Orders') {
    $view->viewVars['actions'] = ['cart', 'checkout'];
}
```

And we can now rebake the controller and templates for the OrdersController:

```shell
cd /vagrant/app
bin/cake bake controller orders -f
bin/cake bake view orders -f
```

Assuming you are using test credentials, you can use the card number `4242424242424242` with any CVC and a valid expiration date to successfully complete a purchase.

## Homework Time!

While our cart is getting there - only two more posts to go! - we still need to add a few features to actually complete the transaction process. These features are strictly up to you to implement, though I’ve included pointers where necessary:

- Store the response from stripe in our database. I would create a `payments` table and store all the data related to an order payment there.
- Mark an order as “paid”. Once paid, we can then do any extra processing necessary. Perhaps trigger a Cake Event that we can use to handle the actual “shipping” of products.
- Ensure that user’s don’t accidentally pay twice. We can do this by making any retrieval of the `Order` require that an order be in a `pending` state (and make all orders pending by default). You can quite easily write a migration for this.
- Add a *Successful Payment* page that we redirect to once payment has been made.
- Add an Order status page, as well as a page to view all of a user’s orders.

Be sure to follow along via twitter on [@savant](https://twitter.com/savant). If you’d like to subscribe to this blog, you may follow the [rss feed here](http://josediazgonzalez.com/atom.xml). Also, all posts in the series will be conveniently linked on the sidebar of every post in the 2014 CakeAdvent Calendar. Come back tomorrow for more delicious content.


