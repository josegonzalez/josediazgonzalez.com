---
  title:       "Paginating one table while sorting by a field from another table"
  date:        2016-03-10 20:51
  description: "How do I sort paginated data in cakephp 3 by a field from a different table"
  category:    cakephp
  tags:
    - cakephp
    - table
    - model
    - pagination
  comments:    true
  sharing:     true
  published:   true
  layout:      post
  disable_advertisement: false
---

There was a user on irc who asked the question, "How do I sort pagination of one table by another table's field?". I actually had to dig a little but to do this. Let's layout how pagination works first.

> Note: all of this will assume Users belongsTo Cities. YMMV for anything else, I definitely didn't test it.

You can paginate by specifying a Table object:

```php
$users = $this->paginate($this->Users);
```

You can also specify the string name:


```php
$users = $this->paginate('Users');
```

Finally, you can pass in a query object (which can be retrieved from a `find()` call):

```php
$query = $this->Users->find();
$users = $this->paginate($query);
```

Of course, if you wanted to include related data, you would need to contain that data, which is where the `query` method shines, as you can easily modify it:

```php
$query = $this->Users->find()
                     ->contain('Cities');
$users = $this->paginate($query);
```

One thing of note is that you can also specify the query info in a controller's `$this->paginate` attribute:

```php
$this->paginate['contain'] = ['Cities'];
$users = $this->paginate('Users');
```

If you wanted to sort the output by a related field, you can add it to the query:

```php
$query = $this->Users->find()
                     ->contain('Cities')
                     ->order(['Cities.name' => 'DESC']);
$users = $this->paginate($query);
```

The above works fine, but this won't:

```php
$this->paginate['contain'] = ['Cities'];
$this->paginate['order'] = ['Cities.name' => 'DESC'];
$users = $this->paginate('Users');
```

Why? Because in the former, we are passing in the order via a query object explicitly. In the later, CakePHP will strip it out because the related field is **not** whitelisted for pagination sorting. The scope of this is limited to the paginated model by default. This is to avoid people futzing with your querystring parameters and taking down your site because of an un-indexed sort...

> ALWAYS ADD INDEXES FOR FIELDS YOU ARE SORTING ON

What if you wanted to use the `$this->paginate` method? You can do this by adding to the `sortWhitelist` option:

```php
$this->paginate['contain'] = ['Cities'];
$this->paginate['order'] = ['Cities.name' => 'DESC'];
$this->paginate['sortWhitelist'] = $this->Users->schema()->columns() + ['Cities.name'];
$users = $this->paginate('Users');
```

Yay! You might notice that I added `$this->Users->schema()->columns()` to the `sortWhitelist` as well. Since it is a whitelist, if I don't whitelist the primary tables fields, I won't be able to sort via those fields. You can of course restrict the fields:

```php
$this->paginate['contain'] = ['Cities'];
$this->paginate['order'] = ['Cities.name' => 'DESC'];
// id and created will be fields in the Users table
$this->paginate['sortWhitelist'] = ['id', 'created', 'Cities.name'];
$users = $this->paginate('Users');
```

Note that if you want to be able to sort by other fields than the one passed explicitly in a query object, you'll need to mix the two methods:

```php
$this->paginate['sortWhitelist'] = $this->Users->schema()->columns() + ['Cities.id', 'Cities.name'];
$query = $this->Users->find()
                     ->contain('Cities')
                     ->order(['Cities.name' => 'DESC']);
$users = $this->paginate($query);
```

### What method should I use?

The `$this->paginate` method is pretty simple to use in a pinch. Doesn't require much change from 2.x. I would use it for a one-off pagination setup.

The `$query` method is useful if you have a complex find or want to reuse that find in another method, as you can abstract the query object behind a cakephp custom find.
