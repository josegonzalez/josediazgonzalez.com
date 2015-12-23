---
  title:       "Using InstanceConfigTrait for object configuration"
  date:        2015-12-22 12:00
  description: "Silly hacks you can use in your cakephp applications"
  category:    cakephp
  tags:
    - cakeadvent-2015
    - cakephp
    - configuration
  comments:    true
  sharing:     true
  published:   true
  layout:      post
  series:      CakeAdvent-2015
---

When writing a new class to handle complex logic, you typically have some amount of configuration you need to set. For instance, lets assume we have a cat class:

```php
<?php
namespace Animalia\Chordata\Mammalia\Carnivora\Feliformia\Felidae\Felinae\Felis;

class FelisCatus
{
  public $attributes = [];
  public function __construct(array $attributes = [])
  {
    $this->attributes = $attributes;
  }
}
?>
```

The above is a simple - other than that namespace yeesh - cat class, where all attributes are set without regard to what is necessary to define a cat. In our case, we want to ensure each cat at least has a color, gender, name, and size:

```php
<?php
namespace Animalia\Chordata\Mammalia\Carnivora\Feliformia\Felidae\Felinae\Felis;

class FelisCatus
{
  public $attributes = [];
  public function __construct(array $attributes = [])
  {
    $this->attributes = array_merge([
      'name' => 'Cat',
      'color' => 'black',
      'gender' => 'female',
      'size' => 'small',
    ], $attributes);
  }
}
?>
```

How do we access the attributes?

```php
$cat = new FelisCatus(['name' => 'Camila']);
// get the name
echo $cat->attributes['name'];

// get the paw size? Undefined index!
echo $cat->attributes['paw_size'];
```

If we were doing this in CakePHP, we could take advantage of the `InstanceConfigTrait`:


```php
<?php
namespace Animalia\Chordata\Mammalia\Carnivora\Feliformia\Felidae\Felinae\Felis;

use Cake\Core\InstanceConfigTrait;

class FelisCatus
{
  use InstanceConfigTrait;
  protected $_defaultConfig = [
    'name' => 'Cat',
    'color' => 'black',
    'gender' => 'female',
    'size' => 'small',
  ];

  public function __construct(array $attributes = [])
  {
    // will automatically merge the attributes with
    // $this->_defaultConfig
    $this->config($attributes);
  }
}
?>
```

Now we get to do the following!


```php
$cat = new FelisCatus(['name' => 'Camila']);
// get the name
echo $cat->config('name');

// get the paw size? Returns null
echo $cat->config('paw_size');

// set the paw size
$cat->config('paw_size', 'small');

// set nested data
$cat->config('appetite.morning', null);
$cat->config('appetite.afternoon', 'hangry');

// get nested data
echo $cat->config('appetite.afternoon');

// set lots of info at once
$cat->config([
  'size' => 'large',
  'pregnant' => true,
  'owner' => 'Jose',
]);
```

The `InstanceConfigTrait` is a useful trait for hiding instance configuration initializing/setting/getting/deleting from the user. You can simply `use` it in your class, ensure you initialze any config in your constructor, and then access it through a simple interface.

CakePHP actually uses this in quite a few places:

- Cache and Log Engines
- Authorize and Authenticate classes
- Password Hashers
- Helpers, Components, Behaviors
- Dispatch Filters
- Mailers
- etc.

So the same interface is available basically everywhere. Its static class analogue is `StaticConfigTrait`, which *also* parses dsn's from the `url` key, which comes in handy when creating factory-type classes.
