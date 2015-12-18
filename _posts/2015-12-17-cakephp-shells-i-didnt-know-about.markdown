---
  title:       "CakePHP Shells I didn't know about"
  date:        2015-12-17 12:00
  description: "Silly hacks you can use in your cakephp applications"
  category:    cakephp
  tags:
    - cakeadvent-2015
    - cakephp
    - shells
  comments:    true
  sharing:     true
  published:   true
  layout:      post
  series:      CakeAdvent-2015
---

Did you know there is a shell that allows you to enable a plugin after installing it via composer?

```shell
bin/cake plugin load Muffin/Trash
```

You can also load the plugin's bootstrap or routes:

```shell
# I'm not releasing this, so don't try and composer require it
bin/cake plugin load --bootstrap --routes Josegonzalez/Blog
```

Most people installed CakePHP 3 using the [`cakephp/app` project template](http://josediazgonzalez.com/2015/12/09/customizing-your-app-template/), so you have access to both `bake` and `migrations`:

```shell
# migrate all the things!
bin/cake migrations migrate

# get a migration status
bin/cake migrations status

# bake a migration
bin/cake bake migration_snapshot Initial

# bake a form (or really anything else)
bin/cake bake form AddForm
```

If you are running migrations, it may be useful to clear the ORM's cache so that your code is aware of the new fields:

```shell
bin/cake migrations migrate && bin/cake orm_cache clear
```

And if you are deploying code, maybe you want to ensure the cache is set *before* the first user's request comes in, speeding up that initial request:

```shell
bin/cake orm_cache build
```

I'm a big fan of the `server` shell. It allows me to quickly test an app locally without needing to setup a virtualhost or a webserver. Very useful for development, and something I recommend everyone learn to place in their arsenal:

```shell
# specify a port I know won't collide with other stuff I run on my machine
bin/cake server -p 1995
```

In older versions of CakePHP 3, we introduced a full REPL around [boris](https://github.com/borisrepl/boris), but that has since been replaced with [Psysh](http://psysh.org/). It's actually quite nice, and lets me test out new code I've written in various scenarios.

```shell
# yo dawg, i hurd u liek shells, so I put a shell in your shell so you can shell while you shell!
bin/cake console
# Note: it saves your history, just like a regular shell, which is nice :)
```

And finally, something I missed from my short stint doing Ruby on Rails, being able to list routes in an application.

```shell
# list routes
bin/cake routes

# see what a url route maps to internally
bin/cake routes check /articles

# generate the url route for a key:pair setup
bin/cake routes generate controller:Articles action:view 2
```

## Bonus!

A shell I discovered a few weeks back is one by the ever-helpful [Loadsys Web Strategies](https://www.loadsys.com/) company. It lets you read into keys were loaded into configure (which is great if you have an app with several `Configure::load()` statements and don't know where a key might be):

```shell
# install it
composer require loadsys/cakephp-config-read:~3.0

# load it
bin/cake plugin load ConfigRead

# use it (on your debug mode)
bin/cake config_read debug

# on your application's encoding
bin/cake config_read App.encoding

# on the default database configuration
bin/cake config_read Datasources.default
```

Is there a CakePHP Shell you'd like to see ported from another framework? Something you find useful or lacking? Leave a note in the comments.
