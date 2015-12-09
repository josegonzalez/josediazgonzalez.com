---
  title:       "Debugging Data in CakePHP 3"
  date:        2015-12-08 12:00
  description: "Silly hacks you can use in your cakephp applications"
  category:    cakephp
  tags:
    - cakeadvent-2015
    - cakephp
    - table
    - softdelete
  comments:    true
  sharing:     true
  published:   true
  layout:      post
  series:      CakeAdvent-2015
---

Since upgrading to CakePHP 3, you may have noticed a few changes. Yes, it's faster, better for your cholesterol, and likely good for your Vitamin D intake<sup>[1]</sup>. However, what I'm referring to is the nicer debugging output.

Typically when you debug an object in PHP, you use something like `print_r()` or `var_dump()`. With scalar types - `int`, `float`, `string` and `bool` - you'll get a pretty simple representation:

```php
php > $i = 1;
php > var_dump($i);
int(1)
```

Thats really all you need. But if you try doing the same thing with an object:

```php
class Person
{
  public $name = 'Alex Super Tramp';
  public $age = 100;
  private $property = 'property';
}

// debugging
php > $p = new Person;
php > var_dump($p);
class Person#1 (3) {
  public $name =>
  string(16) "Alex Super Tramp"
  public $age =>
  int(100)
  private $property =>
  string(8) "property"
}
```

You get pretty verbose output on that object. For simple objects, this might not be so bad, but the problem is compounded when you are trying to debug a `Table` class, or a `Controller` etc. Fortunately, in CakePHP 3 we take advantage of a special magic method, `__debugInfo()`.

## Magic Methods to the rescue

Since PHP 5.6, you can add the method `__debugInfo()` to any class. When instances of said class are passed through `var_dump()`, PHP will automatically use the `array` returned by this method to display debug info about that instance.

If the method is omitted, PHP will fallback to outputting *all* properties in that instance. Here is a lovely example of this in action.

```php
class Person
{
  public $name = 'Alex Super Tramp';
  public $age = 100;
  private $property = 'property';
  public function __debugInfo()
  {
    return ['name' => $this->name];
  }
}

// debugging
php > $p = new Person;
php > var_dump($p);
object Person#1 (1) {
  ["name"] =>
  string(16) "Alex Super Tramp"
}
```

Fancy, right? Remember, while CakePHP *does* support this feature automatically in 5.6, users of older PHP versions will fallback to the old, yucky data dump.

## How this affects you

There are a few places where `__debugInfo()` has been useful:

- `Form` instances output metadata about the schema, errors, and validation rules.
- `ResultSet` instances output the query that is executed.
- `Cell` objects will output the environment in which they were created (view layer as well as the current request/response objects).
- `Entities` will output a plethora of data regarding the current state of the entity. Useful for seeing if the entity is new or has been changed.

You're also quite welcome to add your own `__debugInfo()` methods to custom classes. For those of you who are curious, I definitely recommend looking at the list of [PHP Magic Methods](https://secure.php.net/manual/en/language.oop5.magic.php), which might just be handy<sup>[2]</sup> in a pinch!

---

[1]: If you work less because you are working smarter, you are more likely to go outside and get some Sun. Remember to do that every so often!

[2]: My current favorite magic method is the `__invoke()` method :)
