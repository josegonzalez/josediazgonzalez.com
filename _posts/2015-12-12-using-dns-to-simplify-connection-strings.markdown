---
  title:       "Using DSNs to simplify connection strings"
  date:        2015-12-12 12:00
  description: "Silly hacks you can use in your cakephp applications"
  category:    cakephp
  tags:
    - cakeadvent-2015
    - cakephp
    - dsn
    - config
  comments:    true
  sharing:     true
  published:   true
  layout:      post
  series:      CakeAdvent-2015
---

In CakePHP 3, we consolidated most configuration into a single `config/app.php`. This superscedes the old method of changing your `config/core.php` and `config/database.php` - as well as any other random configuration values you might set. This is good for a lot of reasons - who wants to deal with a `DATABASE_CONFIG`? - but also means we can simplify how we configure things.

One thing that always irked me was the inability to specify connection information in a single way. For instance, you might specify the host for a datastore with the following keys:

- `host`: For databases
- `server`: For a redis caching server
- `servers`: For memcached servers

One of quite a few different ways configuring CakePHP was yuck. A nice improvement in CakePHP 3 is the ability to specify connection information via a Data source name (DSN).

A DSN is a standard used by many programming communities to encode all the information about a particular configuration. For instance, here is how I might tell you to connect to my local `test` database:

```php
$dsn = "mysql://root:cakeisali3@localhost:3306/test";
```

The above encodes the following information:

- `scheme`: `mysql`
- `user`: `root`
- `password`: `cakeisali3`
- `host`: `localhost`
- `port`: `3306`
- `database`: `test`

You can also specify optional arguments via querystring:

```php
$dsn = "mysql://root:cakeisali3@localhost:3306/test?encoding=utf8";
```

In 3.x, the following can now use a special `url` key. This key will be parsed and it's values will be used to connect to a database. The following classes can be configured via dsn:

- Database connections
- Cache connections
- Log information
- Email configuration

You can also take advantage of this magic parsing by including the `\Cake\Core\StaticConfigTrait` trait in your own classes.

One thing that might be useful would be to extend the default schemes. In CakePHP, we map the `scheme` to a particlar namespaced-class in the CakePHP core. You might add a `Mongo`-based ORM Driver, but if it isn't mapped, your app will go boom. You can map one easily though!

```php
ConnectionManager::dsnClassMap(['console' => 'App\Database\Driver\Mongo'])
// also works on the following classes:
// - Cache::dsnClassMap()
// - Email::dsnClassMap()
// - Log::dsnClassMap()
```

It's a nifty trick I think, and one that should prove useful to anyone using cloud-providers such as [Heroku](https://www.heroku.com/) or [Dokku](http://dokku.viewdocs.io/dokku/) for application deployment.
