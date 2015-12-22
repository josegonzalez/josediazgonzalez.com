---
  title:       "Managing Application Configuration"
  date:        2015-12-18 12:00
  description: "Silly hacks you can use in your cakephp applications"
  category:    cakephp
  tags:
    - cakeadvent-2015
    - cakephp
    - configuration
    - environment
  comments:    true
  sharing:     true
  published:   true
  layout:      post
  series:      CakeAdvent-2015
---

Most applications have a few custom bits of configuration. For instance, you might configure your error handler, or add some special facebook authentication key. Generally, these fall into two categories:

- configuration specific to the application (how errors are handled)
- configuration specific to the environment (which key to use for a service in staging/prod)

For the former, I like creating a directory structure similar to the following:

```shell
$ ls config/
app.php
bootstrap.php
bootstrap_cli.php
bootstrap/environment.php
bootstrap/functions.php
bootstrap/functions_cli.php
bootstrap/keys.php
bootstrap/services.php
paths.php
routes.php
```

Generally speaking, I have a `bootstrap` folder which contains multiple php files I require from my `bootstrap.php`. I use the `_cli` suffix on the filename to denote cli-based configuration. I also separate the config by the type of thing I am configuring, e.g. `keys.php` contains keys for stuff like an S3 bucket, while `services.php` contains a list of services mapping to their `tcp` or `udp` urls.

Sometimes I don't *want* to store this information in the repository. For instance, I might have a specific bit of authentication information for the Facebook application my app is communicating with, or credentials to some SFTP bucket where important documents are stored. Maybe the database credentials are sacred and I don't want everyone on the dev team to connect directly to production. Generally speaking, I have alternatives I would use in this case so that the functionality works both locally and in production, albeit with slightly different data.

In this case, I use `php-dotenv` to configure [environment variables](http://12factor.net/config) for use in my application. Let's install it in our application first:

```shell
composer require josegonzalez/dotenv
```

Normally I add the following bit of code *right* after the composer `vendor/autoload.php` is required in my `config/bootstrap.php`. This will affect both cli and web requests, so there isn't a need to do it twice:

```php
if (!env('APP_NAME')) {
    josegonzalez\Dotenv\Loader::load([
        'filepaths' => [
            __DIR__ . DS . '.env',
            __DIR__ . DS . '.env.default',
        ],
        'toServer' => false,
        'skipExisting' => ['toServer'],
        'raiseExceptions' => false
    ]);
}
```

A few things:

- The [php-dotenv](https://github.com/josegonzalez/php-dotenv) project supports being called in a [non-static way](https://github.com/josegonzalez/php-dotenv#usage) if you hate statics.
- `.env` files are simply a list of `export KEY=VALUE` statements. If you know bash, you know how to use `.env` files. There is a [primer](https://github.com/josegonzalez/php-dotenv#usage) in the readme.
- You can load multiple `.env` files. The first one that exists on disk will be used. This is useful if you have `gitignored` one like I do but wish to provide a default `.env` file
- You can tell `php-dotenv` to populate a number of variables. In this case, I am populating `$_SERVER`.
- By default, exceptions are raised whenever there is an issue loading or parsing a `.env` file. Rather than raise an expection at the bootstrap level, I just turn them off and assume the application has sane defaults. YMMV.

Now, when is this useful? Say I have a default database config, and I store this in my `config/.env.default`:

```shell
# cakephp can read DSNs, remember?
export DATABASE_URL="mysql://user:password@localhost/database?encoding=utf8&timezone=UTC&cacheMetadata=true&quoteIdentifiers=false&persistent=false"
```

And I read it into my `config/app.php` like so:

```php
'Datasources' => [
    'default' => [
        'url' => env('DATABASE_URL'),
    ],
],
```

In production, my `nginx.conf` sets `APP_NAME` and `DATABASE_URL`, and therefore I don't load the default mysql configuration. But what if I didn't? I could create a `config/.env` file on my server with the following:

```shell
export DATABASE_URL="mysql://app:pass@some-host/app-database?encoding=utf8&timezone=UTC&cacheMetadata=true&quoteIdentifiers=false&persistent=true"
```

And my application would be none the wiser. What's even *more* awesome is that I can *also* use this same trick to provide custom environments locally. If I have a developer who has slightly different config than the defaults, they can simply create a `config/.env` file with their own customizations and they are off to the races!
