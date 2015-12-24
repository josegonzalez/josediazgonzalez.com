---
  title:       "Data Validation in CakePHP 3"
  date:        2015-12-23 12:00
  description: "Silly hacks you can use in your cakephp applications"
  category:    cakephp
  tags:
    - cakeadvent-2015
    - cakephp
    - validation
  comments:    true
  sharing:     true
  published:   true
  layout:      post
  series:      CakeAdvent-2015
---

As mentioned before, CakePHP 3 introduced the concept of a distinct Validation class that can be used against an arbitrary array of data. You could _sort of_ do this in CakePHP 2, but it was annoying, not well-exposed, and not well-documented.

Assuming you got stuck in an older version of CakePHP - or some other non-CakePHP 3 environment - and want to use the new validation layer, you'll need to install the cakephp/validation package. Skip this if you are using CakePHP 3 in your app already:

```shell
composer require cakephp/validation
```

> Most CakePHP 3 packages can be installed in a standalone way with minimal external dependencies.

Now, let's start by creating a validator:

```php
# use the class first of course!
use Cake\Validation\Validator;

$validator = new Validator();
```

Here is a bit of data I want to validate:

```php
$data = [
  'name' => 'camila',
  'age' => 4,
  'intelligence' => 'stupid',
  'position' => 'keyboard',
  'species' => '',
];
```

In the 3.x validator, you can easily require the presence of a field:

```php
$validator->requirePresence('species');

// should be an empty array
$errors = $validator->errors($data);
```

Note that this is different from the field being not empty:

```php
$validator->notEmpty('species', 'we need a species for your pet');

// will not be an empty array
$errors = $validator->errors($data);
```

However, this is *not* the same as being an string with just whitespace. For that, you need another rule:

```php
$validator->add('species', [
  'notBlank' => [
      'rule' => 'notBlank',
      'message' => "Ain't no such thing as a '   ' species"
    ]
]);

// will not be an empty array
$errors = $validator->errors($data);
```

You can also nest validators. Say my `$data` array has a field called `kittens`, which is an array of `kitten` data. You might want to validate some information about those kittens:

```php
// add custom rules here
$kittenValidator = new Validator();

// Connect the nested validators.
$validator->addNestedMany('kittens', $kittenValidator);

// includes errors from nested data as well
$validator->errors($data);
```

Some rules - like those surrounding presence of a field - can support multiple modes, `create` and `update`. This is useful for cases where you might be using the same `$validator` against both new and existing recordsets, but want slightly different behavior for one or two rules.

```php
// only require a name on update
$validator->notEmpty(
  'name',
  'Your cat needs a name, you cannot call it cat forever',
  'update' // the mode
);

// errors works in `create` mode by
// default. Set the second arg to
// `false` to use `update` mode
$errors = $validator->errors($data, false);
```

Of course, there are [quite a few rules at your disposal](http://api.cakephp.org/3.0/class-Cake.Validation.Validation.html) by default, but you are welcome to create new ones. Maybe your rule validates that a cat is in a breed that exists in a specific database table?

```php
<?php
namespace App\Model\Validation;

use Cake\ORM\TableRegistry;
use Cake\Validation\Validation;

class CatValidation extends Validation
{
  public static function validSpecies($check)
  {
    $table = TableRegistry::get('Species');
    $species = $table->find('list')->toArray();
    return in_array((string)$check, array_values($species));
  }
}
?>
```

Now you can simply add this new class to your validator:

```php
// map it
// if a class name, the methods *must* be static
$validator->provider('cat', 'App\Model\Validation\CatValidation');

// use it
$validator->add('species', 'validSpecies', [
    'rule' => 'validSpecies',
    'provider' => 'cat'
]);
```
