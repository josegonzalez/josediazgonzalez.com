---
  title:       "Tracking Logged in User Actions"
  date:        2015-12-21 12:00
  description: "Silly hacks you can use in your cakephp applications"
  category:    cakephp
  tags:
    - cakeadvent-2015
    - cakephp
    - auth
    - user-tracking
  comments:    true
  sharing:     true
  published:   true
  layout:      post
  series:      CakeAdvent-2015
---

> Note: for the purposes of this post, I chose an easy to understand plugin, but I recommend using the [footprint](https://github.com/usemuffin/footprint) plugin as it supports many more features than the one I cover here.

This is a pretty straightforward post. In CakePHP 3, we've removed a lot of the ability to access the session except where there is a `Request` object. Static access to `CakeSession` is gone, and it's not coming back, so please stop asking for it. And stop using `$_SESSION`, that breaks the cake.

One thing this affects is the ability to see user session data in the Model layer. Typically you want to track _who_ performed an action *when* the action happens. It's quite nice to hide this in your model layer, as opposed to mangling data when it's going into an entity.

How do we do this? We can use the [`ceeram/blame` plugin](https://github.com/ceeram/blame)!

```shell
# ugh more things to install
composer require ceeram/cakephp-blame

# load it
bin/cake plugin load Ceeram/Blame
```

Now we add the following `use` call to the inside of our `src/Controller/AppController.php` class:

```php
class AppController extends Controller
{
  use \Ceeram\Blame\Controller\BlameTrait;
}
```

And finally add the behavior to our table:

```php
public function initialize(array $config)
{
    $this->addBehavior('Ceeram/Blame.Blame');
}
```

Now whenever a new record is saved, the `created_by` field is set to the logged in user's `id`. When records are modified, the `modified_by` field will be set.

## How does it work?

The `BlameTrait` we added to our `AppController` actually does all the heavy lifting. It adds a [listener](https://github.com/ceeram/blame/blob/master/src/Event/LoggedInUserListener.php) that will add the appropriate data to our Table instances whenever they are saved through the magic of [`Controller::loadModel()`](https://github.com/ceeram/blame/blob/master/src/Controller/BlameTrait.php#L18).

It's actually quite clever, and I'm a bit upset I hadn't previously thought of it. The same trick probably works in 2.x.

For users that find this plugin limiting in some way, I definitely recommend reading the code over, extending it, or applying the clever usage of the event system to your own application.
