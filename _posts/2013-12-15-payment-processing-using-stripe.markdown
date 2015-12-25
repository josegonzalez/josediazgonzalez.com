---
  title:       "Payment Processing using Stripe"
  date:        2013-12-15 01:19
  description: "Making money with your website should be your primary concern, and this blog post will explain a simple, awesome way to do so"
  category:    cakephp
  tags:
    - aliasing
    - cakeadvent-2013
    - cakephp
    - sessions
  comments:    true
  sharing:     true
  published:   true
  layout:      post
  series:      CakeAdvent-2013
---

> This tutorial assumes you are using the FriendsOfCake/app-template project with Composer. Please see [this post for more information](/2013/12/08/composing-your-applications-from-plugins/).

One thing lots of developers struggle with is collecting payment information. In recent years, there have been a few companies that have put out excellent apis, simplifying this process. Today we'll use Stripe to setup payment processing.

## Initial Setup

The first thing you'll want to do is [sign up for stripe](https://stripe.com/). We'll work using in Test mode for now, so no need to activate the account just yet. You can do so when you're ready to go into production.

Once you've signed up, we'll install the [Stripe Plugin from chronon](https://github.com/chronon/CakePHP-StripeComponent-Plugin). Run the following command in your shell to install it via composer:

```shell
composer require chronon/stripe 2.0.0
```

Your output should be similar to the following:

![http://cl.ly/image/0s0b1x062j3d](http://cl.ly/image/0s0b1x062j3d/Screen%20Shot%202013-12-15%20at%202.31.33%20AM.png)

Next, we should ensure that the base Stripe libraries are included within your CakePHP app. We'll also need to load the plugin. Add the following to your `app/Config/bootstrap.php`:

```php
<?php
// Either this
if (!include (ROOT . DS . 'vendor' . DS . 'autoload.php')) {
  trigger_error("Unable to load composer autoloader.", E_USER_ERROR);
  exit(1);
}

// Or the following will work
App::import('Vendor', array('file' => 'autoload'));

// ALSO: Load the plugin
CakePlugin::load('Stripe');
?>
```

Now we need some configuration. I'll use the following configuration - and a separate logging config - though you can modify it as necessary:

```php
<?php
Configure::write('Stripe', array(
  'currency' => 'usd',
  'fields' => array(
    'stripe_id' => 'id',
    'stripe_last4' => array('card' => 'last4'),
    'stripe_address_zip_check' => array('card' => 'address_zip_check'),
    'stripe_cvc_check' => array('card' => 'cvc_check'),
    'stripe_amount' => 'amount'
  ),
  'LiveSecret' => 'sk_live_LIVE_SECRET_KEY', // from https://manage.stripe.com/account/apikeys
  'mode' => 'Test',
  'TestSecret' => 'sk_test_TEST_SECRET_KEY', // from https://manage.stripe.com/account/apikeys
));

CakeLog::config('stripe', array(
    'engine' => 'FileLog',
    'types' => array('info', 'error'),
    'scopes' => array('stripe'),
    'file' => 'stripe',
));
?>
```

Now we'll want to add it to our `$components` array of our new `app/Controller/OrdersController.php` file:

```php
<?php
class OrdersController extends AppController {
  public $components = array(
    'Stripe.Stripe'
  );

  // Disable the use of a model for now
  public $uses = null;

  public function checkout() {
  }
}
?>
```

## Frontend Integration

> Some of the following is replicated from the [official Stripe documentation](https://stripe.com/docs/tutorials/forms) to make it easier to follow this tutorial.

One of the ways in which you can increase conversion is to avoid a redirect offsite. Every step a user has to complete is liable to make the user less likely to convert, so keeping everything on one-page would be ideal. We'll use Stripe's custom form api to keep everything in-house.

Add the following bit of javascript to your `app/View/Orders/checkout.ctp`:

```php
<script type="text/javascript" src="http://code.jquery.com/jquery-1.10.2.js"></script>
<script type="text/javascript" src="https://js.stripe.com/v2/"></script>
<script type="text/javascript">
  Stripe.setPublishableKey('<?php echo Configure::read('Stripe.TestPublishableKey'); ?>');
</script>
```

You'll notice we include the `stripe.js` library, as well as set our publishable api (different from the secret key!). Now we'll create the following form:

```php
<?php
echo $this->Form->create('Order', array('class' => 'payment-form'));
echo '<span class="payment-errors"></span>';
echo $this->Form->input('Order.number', array('label' => 'Card Number'));
echo $this->Form->input('Order.cvc', array('label' => 'CVC'));
echo $this->Form->input('Order.exp-month', array('label' => 'Expiration Month (MM)'));
echo $this->Form->input('Order.exp-year', array('label' => 'Expiration Year (YYYY)'));
echo $this->Form->end();
?>
```

We will not be submitting directly from this form to the server. Instead, we'll process it the following javascript (using the jQuery library) that you should place within `<script></script>` tags in your `app/View/Orders/checkout.ctp`:

```javascript
jQuery(function($) {
  $('.payment-form').submit(function(e) {
    // Prevent the form from submitting with the default action
    e.preventDefault();

    var $form = $(this);

    // Disable the submit button to prevent repeated clicks
    $form.find('button').prop('disabled', true);

    Stripe.card.createToken({
      number: $('#OrderNumber').val(),
      cvc: $('#OrderCvc').val(),
      exp_month: $('#OrderExp-month').val(),
      exp_year: $('#OrderExp-year').val()
    }, stripeResponseHandler);
  });
});
```

When we create a form for checkout, we need to use a custom stripe token for the specific order. This token is made of the data from the user's credit card info etc., and helps keep the user's data away from our servers so that we do not have to handle privacy concerns. We created a token using `Stripe.card.createToken` and setup a specific response handler, `stripeResponseHandler`. Our `stripeResponseHandler` will do the heavy lifting of submitting to the site:

```javascript
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
    $('#OrderNumber, #OrderCvc, #OrderExp-month, #OrderExp-year').val("");
    // Insert the token into the form so it gets submitted to the server
    $form.append($('<input type="hidden" name="data[Order][stripeToken]" />').val(token));
    // and submit
    $form.get(0).submit();
  }
};
```

Now lets add some debugging code to our controller action and submit it:

```php
<?php
  public function checkout() {
    if ($this->request->is('post')) {
      debug($this->request->data);die;
    }
  }
?>
```

We should have output similar to the following:

![http://cl.ly/image/2R2l3X0E1Q3M](http://cl.ly/image/2R2l3X0E1Q3M/Screen%20Shot%202013-12-15%20at%204.08.43%20AM.png)

## Server Integration

At this point, we have a stripeToken that can be used to charge a user *once*. We can do this with a small bit of PHP code:

```php
<?php
  public function checkout() {
    if ($this->request->is('post')) {
      $data = array(
        'amount' => '13.37',
        'stripeToken' => $this->request->data('Order.stripeToken'),
        'description' => 'CakeAdvent Calendar (large)'
      );
      $result = $this->Stripe->charge($data);
      debug($result);die;
    }
  }
?>
```

For successful calls, the output would be as follows:

![http://cl.ly/image/1O380a2U2c0x](http://cl.ly/image/1O380a2U2c0x/Screen%20Shot%202013-12-15%20at%204.17.40%20AM.png)

Unsuccessful calls would return an error message as a string. For example, re-using the token would result in the following output:

![http://cl.ly/image/0h0n0m3s2V3z](http://cl.ly/image/0h0n0m3s2V3z/Screen%20Shot%202013-12-15%20at%204.20.42%20AM.png)

## Onwards and upwards

The above walked you through charging a user for a predefined amount. We can go forwards lots of ways:

- Build a cart system and use the amount there as the charge
- Submit [more user info](https://stripe.com/docs/checkout#integration-simple-parameters), such as name, address, etc.
- Create customers for the purposes of charging subscription fees
- Keep order histories on your site for later customer viewing
- Integrate this with a shipping api such as [EasyPost](https://www.easypost.com/)
- Keep your users in the loop using the [Twilio](https://www.twilio.com/) api

Setting up payment processing in CakePHP shouldn't ever be hard, so dive in and start making money today.
