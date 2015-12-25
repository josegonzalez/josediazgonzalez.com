---
  title:       "Sending email invoices to users on payment"
  date:        2014-12-15 13:42
  description: "Part 6 of 7 in a series of posts designed to teach you how to use CakePHP 3 effectively"
  category:    cakephp
  tags:
    - cakeadvent-2014
    - cakephp
    - email
    - templates
  comments:    true
  sharing:     true
  published:   true
  layout:      post
  series:      CakeAdvent-2014
---

Once a user has made a purchase, they will likely want some sort of proof that the purchase went through. We can send them an email at every step of the way. We’ll start by sending an email as soon as the purchase was completed.

CakePHP’s email system allows us to use Templates to send email. We previously briefly covered email sending while building the anonymous issue tracker - though simply using raw messages. CakePHP is capable of sending messages both as plaintext and as html, and is also capable of wrapping emails in layouts. Here is a simple, contrived example:

```php
// Load the class at the top of your class using the `use` statement
use Cake\Network\Email\Email;
// Construct an email object
$email = new Email();
// Send the email using the template in `src/Template/Email/TYPE/herp.ctp`
// and the layout in `src/Template/Layout/Email/TYPE/derp.ctp`
// Type is the type of the message
$email->template('herp', 'derp');
// Send the email as a multi-part type message, both as `text` and `html`.
// This means that the previous `template` call configures 4 different
// files for use when sending
$email->emailFormat('both');
// Send the email to this user
$email->to('camilla@number1.com');
// Specify this user to send as
$email->from('app@domain.com');
// Actually send the email!
$email->send();
```

What we are going to do is send a simple, plain-text email that uses a text template and a text layout. Let’s start by creating a `src/Template/Email/text/purchase.ctp` file with the following contents:

```php
Hi!
We're messaging you to let you know someone made a purchase for <?= $amount ?> at <?= $purchase_time ?> under the email <?= $user['email'] ?>. If this seems incorrect, let us know!
The following items were purchased:
<?php foreach ($order_items as $order_item) :?>
- <?= $order_item->product->name ?>: $<?= $order_item->price ?>
<?php endforeach; ?>
If you have any questions, feel free to respond to this email!
- Awesome Store
```

> While we won’t modify the default text layout, please note that the default CakePHP layouts contain a message stating that the email was sent from the CakePHP framework. You can remove these if you like

Now that we have our email set, lets create a new event in our `app/config/events.php` that we can use to send the email. We’ll call it `Order.postPurchase`:

```php
use Cake\Network\Email\Email;
EventManager::instance()->attach(function (Event $event) {
  $amount = $event->data['amount'];
  $order_items = $event->data['order']->order_items;
  $purchase_time = date('Y-m-d H:i:s');
  $user = $event->data['user'];
  $email = new Email();
  $email->template('purchase', 'default')
      ->emailFormat('text')
      ->to($user['email'])
      ->from('store@example.com')
      ->viewVars(compact('amount', 'order_items', 'purchase_time', 'user'))
      ->send();
}, 'Order.postPurchase');
```

Next, we’ll ensure we actually trigger this event in our `checkout` action. Modify the bake `checkout.ctp` element to include the following when the `$response->isSuccessful()`:

```php
$event = new \Cake\Event\Event('Order.postPurchase', $this, [
    'amount' => $amount,
    'order' => $order,
    'user' => $this->Auth->user(),
]);
\Cake\Event\EventManager::instance()->dispatch($event);
```

You’ll need configure your email settings in `app/config/app.php`, but once you do, we will be sending users email whenever they’ve successfully completed a purchase! Note that now that we are using templates, we can *also* use helpers as you would in any other template file, which allows you to build more complex emails and drive campaigns to users.

## Homework Time

You can actually do a few cool things with email - that I’ve done in other CakePHP websites and other frameworks:

- Log all emails to CLI and the Database when in Debug mode so that you can view what *would* have been sent to a user instead of potentially spamming users. CakePHP allows you to build arbitrary Transport classes to make this possible.
- Make a PostPurchaseEmail class that can take all it’s configuration within the constructor. This way you can simply instantiate that particular email class and let it worry about how it should configure the email.
- Send both an html and a text representation of the same email. [Mailchimp provides some templates](http://templates.mailchimp.com/) you can model your email layouts after to get wider email client support.

Be sure to follow along via twitter on [@savant](https://twitter.com/savant). If you’d like to subscribe to this blog, you may follow the [rss feed here](/atom.xml). Also, all posts in the series will be conveniently linked on the sidebar of every post in the 2014 CakeAdvent Calendar. Come back tomorrow for more delicious content.

