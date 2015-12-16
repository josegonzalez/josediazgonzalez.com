---
  title:       "The Collection Class and You"
  date:        2015-12-13 12:00
  description: "Silly hacks you can use in your cakephp applications"
  category:    cakephp
  tags:
    - cakeadvent-2015
    - cakephp
    - collections
  comments:    true
  sharing:     true
  published:   true
  layout:      post
  series:      CakeAdvent-2015
---

Many modern applications work on a set of results, iterating over them, manipulating them, and modifying them to display the output necessary to get a job done. In CakePHP 3, we introduced the helpful `Collection` class.

Here we have an array of cats info:

```php
$cats = [
  [
    'name' => 'camila',
    'gender' => 'female',
    'type' => 'calico',
    'size' => 'small',
  ],
  [
    'name' => 'railroad',
    'gender' => 'male',
    'color' => 'gray',
    'size' => 'massive',
  ],
  [
    'name' => 'santo',
    'gender' => 'male',
    'color' => 'black',
    'size' => 'massive',
  ],
  [
    'name' => 'jax',
    'gender' => 'male',
    'color' => 'black',
    'size' => 'small',
  ],
];
```

Lets filter out all the ~~best~~ female cats:

```
// filter the data
$femaleCats = [];
foreach ($cats as $cat) {
  if ($cat['gender'] == 'female') {
    $femaleCats[] = $cat;
  }
}
// $femaleCats should now contain camila, the cat on your right.
```

Lets see what this looks like with the Collection class:

```php
// instantiate a new collection
$collection = new \Cake\Collection\Collection($cats);

// or use the helper function if you *really* want to
$collection = collection($cats);

// and now filter the data
$femaleCats = $collection->filter(function ($cat) {
    return $cat['gender'] == 'female;
});

// $femaleCats is a Collection instance that contains one cat
```

Thats quite a bit simpler, though sometimes you want an array of data:

```php
$femaleCats->toArray();
```

You can also chain collection methods:

```php
$collection
  // get all the small cats
  ->filter(function ($cat) { return $info['size'] == 'small'; })
  // if they are black
  ->filter(function ($cat) { return $info['color'] == 'black'; })
  // if they are female
  ->filter(function ($cat) { return $info['gender'] == 'female'; })
  // and sort alphabetically by name descending
  ->sortBy('name', SORT_DESC);
```

Pretty neat. Collections can work on any `array` or instance that implements the `Traversable` interface. In CakePHP, you can use any Collection method on the `ResultSet` object returned by a query, which is pretty powerful for making complex find methods.
