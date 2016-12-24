---
  title:       "Order status notifications"
  date:        2016-12-23 08:30
  description: "Part 23 of a series of posts that will help you build out a personal CMS"
  category:    cakephp
  tags:
    - emails
    - mailers
    - orders
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

## Order Mailer for email notifications

First thing is we'll need an OrderMailer to handle all the actual email sending. Here is mine:

```php
<?php
namespace PhotoPostType\Mailer;

use Cake\Core\Configure;
use Cake\Mailer\Mailer;
use Josegonzalez\MailPreview\Mailer\PreviewTrait;

class OrderMailer extends Mailer
{

    use PreviewTrait;

    /**
     * Email sent on new order
     *
     * @param array $email User email
     * @param string $token Token used for validation
     * @return \Cake\Mailer\Mailer
     */
    public function newOrder($data)
    {
        $this->loadModel('PhotoPostType.Orders');
        $order = $this->Orders->get($data['order_id']);
        return $this->to(Configure::read('Primary.email'))
            ->subject('New Order')
            ->template('PhotoPostType.new_order')
            ->set($order)
            ->emailFormat('html');
    }

    /**
     * Email sent on order received
     *
     * @param array $email User email
     * @param string $token Token used for validation
     * @return \Cake\Mailer\Mailer
     */
    public function received($data)
    {
        $this->loadModel('PhotoPostType.Orders');
        $order = $this->Orders->get($data['order_id']);
        return $this->to($order->email)
            ->subject('Order Received!')
            ->template('PhotoPostType.received')
            ->set($order)
            ->emailFormat('html');
    }

    /**
     * Email sent on order shipped
     *
     * @param array $email User email
     * @param string $token Token used for validation
     * @return \Cake\Mailer\Mailer
     */
    public function shipped($data)
    {
        $this->loadModel('PhotoPostType.Orders');
        $order = $this->Orders->get($data['order_id']);
        return $this->to($order->email)
            ->subject('Order Shipped!')
            ->template('PhotoPostType.shipped')
            ->set($order)
            ->emailFormat('html');
    }
}
```

I've defined three different types of emails:

- `newOrder`: Sent to the email configured at `Primary.email` when we get a new order
- `received`: Sent to the orderer when we've received their order
- `shipped`: Sent to the orderer when we've shipped their email

I added the following to my `config/.env` and `config/.env.default` to configure the `Primary.email`:

```shell
export PRIMARY_EMAIL="example@example.com"
```

Here are my html templates for each email, which I've placed in `plugins/PhotoPostType/Template/Email/html/`. You can create equivalent text templates as well:

#### `plugins/PhotoPostType/Template/Email/html/new_order.ctp`

```php
<h2>There was a new order</h2>

<p>
    See the new order <?= $this->Html->link('here', \Cake\Routing\Router::url([
        'plugin' => 'PhotoPostType',
        'controller' => 'Orders',
        'action' => 'index',
        $token
    ], true)); ?>
</p>

<p>
    Order details:
</p>
<dl>
    <dt>name</dd>
    <dd><?= $order->name ?></dd>

    <dt>address</dd>
    <dd><?= $order->address_line_1 ?></dd>

    <dt>zip</dd>
    <dd><?= $order->address_zip ?></dd>

    <dt>state</dd>
    <dd><?= $order->address_state ?></dd>

    <dt>city</dd>
    <dd><?= $order->address_city ?></dd>

    <dt>countrys</dd>
    <dd><?= $order->address_country ?></dd>
</dl>
```

#### `plugins/PhotoPostType/Template/Email/html/received.ctp`

```php
<h2>Your order was recieved</h2>
<p>
    Thanks for your order! We will be shortly shipping out your order to the following address:
</p>
<dl>
    <dt>name</dd>
    <dd><?= $order->name ?></dd>

    <dt>address</dd>
    <dd><?= $order->address_line_1 ?></dd>

    <dt>zip</dd>
    <dd><?= $order->address_zip ?></dd>

    <dt>state</dd>
    <dd><?= $order->address_state ?></dd>

    <dt>city</dd>
    <dd><?= $order->address_city ?></dd>

    <dt>countrys</dd>
    <dd><?= $order->address_country ?></dd>
</dl>
<p>Thanks again, and enjoy!</p>
```

#### `plugins/PhotoPostType/Template/Email/html/shipped.ctp`

```php
<h2>Your order was shipped</h2>
<p>
    Thanks for your order! Here are your order details:
</p>
<dl>
    <dt>name</dd>
    <dd><?= $order->name ?></dd>

    <dt>address</dd>
    <dd><?= $order->address_line_1 ?></dd>

    <dt>zip</dd>
    <dd><?= $order->address_zip ?></dd>

    <dt>state</dd>
    <dd><?= $order->address_state ?></dd>

    <dt>city</dd>
    <dd><?= $order->address_city ?></dd>

    <dt>countrys</dd>
    <dd><?= $order->address_country ?></dd>
</dl>
<p>Thanks again, and enjoy!</p>
```

Pretty straightforward. I'll commit my changes now.

```shell
git add config/.env.default plugins/PhotoPostType/src/Mailer/OrderMailer.php plugins/PhotoPostType/src/Template/Email/html/new_order.ctp plugins/PhotoPostType/src/Template/Email/html/received.ctp plugins/PhotoPostType/src/Template/Email/html/shipped.ctp
git commit -m "Create order status emails"
```

## Shipping Emails

This one was a bit more difficult to figure out where it should go. I want to hook into CakePHP's `Model.afterSave` event as seamlessly as possible. We could add a new event handler to our `OrdersListener` and bind it on the Model as well, but that seems icky. I'm going to instead use model behaviors, which are purpose-built to handle all table events. The following is my `OrderNotificationBehavior`, located at `plugins/PhotoPostType/src/Model/Behavior/OrderNotificationBehavior.php`:

```php
<?php
namespace PhotoPostType\Table\Behavior;

use Cake\Datasource\EntityInterface;
use Cake\Event\Event;
use Cake\ORM\Behavior;
use Josegonzalez\CakeQueuesadilla\Traits;

class OrderNotificationBehavior extends Behavior
{
    use QueueTrait;

    public function afterSave(Event $event, EntityInterface $entity)
    {
        if ($entity->isNew()) {
            $this->push(['\App\Job\MailerJob', 'execute'], [
                'action' => 'received',
                'mailer' => 'PhotoPostType.Orders',
                'data' => [
                    'order_id' => $entity->id

                    'email' => $entity->email,
                    'name' => $entity->shipping_name,
                    'address_line_1' => $entity->shipping_address_line_1,
                    'address_zip' => $entity->shipping_address_zip,
                    'address_state' => $entity->shipping_address_state,
                    'address_city' => $entity->shipping_address_city,
                    'address_country' => $entity->shipping_address_country,
                ]
            ]);

            $this->push(['\App\Job\MailerJob', 'execute'], [
                'action' => 'newOrder',
                'mailer' => 'PhotoPostType.Orders',
                'data' => [;
                    'order_id' => $entity->id
                ],
            ]);
        } elseif ($entity->shipped) {
            $this->push(['\App\Job\MailerJob', 'execute'], [
                'action' => 'shipped',
                'mailer' => 'PhotoPostType.Orders',
            ]);
        }
    }
}
```

It's pretty straightforward. I am reusing the `MailerJob` to send the emails in the background - awh yis - and sending all three emails depending upon whether:

- The order was just created
- The order was shipped

The `push` method comes from our `QueueTrait`, which helpfully uses the default queue handler to push jobs.

Next, we'll link it up to our `PhotoPostType.Orders::initialize()` method:

```php
$this->addBehavior('OrderNotificationBehavior');
```

And we're done!

```shell
git commit plugins/PhotoPostType/src/Model/Behavior/OrderNotificationBehavior.php plugins/PhotoPostType/src/Model/Table/OrdersTable.php
git commit -m "Send emails when the status of the order changes"
```

## Homework time

You'll notice that the CMS user has no idea what was actually ordered - they'd need to guess this from the charge id in `Stripe`. This kinda bites, so your task is to:

- Track the post id that is being purchased.
- Save that relation to the `orders` table.
- Display a link to what is being purchased on the `/admin/orders` page.

---

> For those that may just want to ensure their codebase matches what has been done so far, the codebase is available on GitHub and tagged as [0.0.23](https://github.com/josegonzalez/cakeadvent-2016/tree/0.0.23).

It's been almost a month, but our CMS is rounding to a close. Our next task is to actually place it online somewhere so our client can view it and suggest any changes. Ideally this happens earlier in the process, but we've only just completed the initial functionality, so it's a reasonable compromise.

Be sure to follow along via twitter on [@savant](https://twitter.com/savant). If you'd like to subscribe to this blog, you may follow the [rss feed here](/atom.xml). Also, all posts in the series will be conveniently linked on the sidebar of every post in the 2016 CakeAdvent Calendar. Come back tomorrow for more delicious content.
