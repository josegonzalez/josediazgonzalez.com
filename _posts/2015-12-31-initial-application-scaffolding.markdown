---
  title:       "Initial Application Scaffolding"
  date:        2015-12-31 12:00
  description: "Planning an initial CakePHP application schema and generating application code using bake."
  category:    cakephp
  tags:
    - cakephp
    - scaffold
    - migrations
    - bake
  comments:    true
  sharing:     true
  published:   true
  layout:      post
  series:      Media Manager
---

## Requirements

Before you continue, you'll want the following stuff on your computer:

- PHP 5.4+. I'm using 5.6 locally, though 7.x should also work fine. Most, if not all, libraries and plugins I am using will work through any supported CakePHP version. I'll let you know if that's ever not the case.
- The following PHP extensions:
  - `ext-intl`
  - `ext-mbstring`
  - `ext-pdo_sqlite`
  - `ext-pdo_mysql`
  - `ext-pdo_pgsql`
- A database! I'm running Postgres locally, but anything supported by the CakePHP Core ORM should do fine. If you use MySQL, I won't attack you.
- A browser. I use Chrome, though any modern browser should work fine with the Javascript I'll be writing.
- [Composer](https://getcomposer.org/download/) installed locally. How you get that is up to you.

We can start once you have the above.

## Pre-planning

> Start out with a goal for the day before you start work. My goal is to scaffold out a small part of my app. I won't have authentication or [file uploading](/2015/12/05/uploading-files-and-images/). I just want a solid database design and some crud-like templating.

Before I begin, I want to outline what my application will probably look like from a datastore perspective:

{% ditaa %}
/-------\    /--------\    /------------\
| Files |<---| Assets |<---| Categories |
\-------/    \--------/    \------------/
    ^            ^ ^
    |            | |
/-------\        | |       /------\
| Users |--------+ +------>| Tags |
\-------/                  \------/
{% endditaa %}

> The above graph was generated with [ditaa](http://ditaa.sourceforge.net/) and some simple ascii art.

I've separated the notion of an `Asset` from a `File`. `Assets` are the things that my users will click on in the admin dashboard, and contain metadata that will be useful to search. Each asset can have one or more `Files` associated with it, has and belongs to many `Tags`, is associated with a single `Category`, and is owned by a `User`.

A `File` is the actual physical file, which will contain size, the directory on whatever storage device I choose, image metadata, etc. I'm choosing to do this as I *think* storing multiple versions of a file as different records will be much easier to reason about in the UI than trying to fiddle with it in code. No real reason other than that.

Note, I *do* have some legacy files I need to import into the new system, but I won't worry about those for now, since it will presumably complicate my datastructure. I'll almost certainly write a script to import the files into my database.

## Initializing our new project

First, lets use composer to generate a project. I'm going to be basing it off of the `0.1.10` release of my [own app skeleton](/2015/12/26/creating-a-generic-cakephp-skeleton/:

```shell
composer create-project --prefer-dist josegonzalez/app:0.1.10 media-manager
```

> From now on, assume you will be working inside of the media-manager root folder.

Before we begin, we need to at least modify our application to read from the correct database. One thing I've done in my new app skeleton is allow configuration via environment variables. Let's start by copying over the defaults to a new file:

```shell
cp config/.env.default config/.env
```

The `.env` file is loaded if it exists, otherwise the `config/env.php` file will fallback to `config/.env.default`. We'll be configuring our app's private configuration here.

Two things I'm going to do first:

- change the `APP_NAME` export to the value `media-manager`.
- Make sure I have a local datastore setup with the credentials `my_app:secret` authed to the database `media-manager`. I mentioned I'm using Postgres, but anything should work.

Once that is set, I can verify that my application works by running the [built-in CakePHP server shell](/2015/12/17/cakephp-shells-i-didnt-know-about/). Run the following and browse to `http://localhost:8765` to verify that you have everything done:

```shell
bin/cake server
```

> I will be using the built-in CakePHP server shell for testing. You can use whatever you'd like, this is just easier for me since I haven't setup Vagrant or Docker for my app skeleton yet.

## Generating a database

Whenever I am building an application, I usually have some vague idea of what my database will look like once I am done. I say usually because sometimes I'm coming up with requirements as I go, which is to say that today is one of those days.

We can generate migration files for our database tables using the `bake` and [`migrations`](/2015/12/10/faster-database-creation-with-migrations/) plugins. I'm allowed to get this wrong because the `migrations` plugin allows me to go back and generate new migrations to fixup any incorrect beliefs about how my application should work.

```shell
# create my assets table
bin/cake bake migration create_assets category_id:integer:index \
                                      user_id:integer:index name \
                                      file_count \
                                      created \
                                      modified

# create the files table. Note that I
# have included a few useful fields for the upload plugin
bin/cake bake migration create_files asset_id:integer:index \
                                     user_id:integer:index \
                                     name \
                                     dir \
                                     size:integer \
                                     type \
                                     metadata \
                                     created \
                                     modified

# categories is simple
bin/cake bake migration create_categories name:string:index \
                                          slug:string:index \
                                          created \
                                          modified

# tags is also simple, though I do need a join table
# there is probably a plugin out there for this but I'm too lazy
bin/cake bake migration create_assets_tags asset_id:integer:unique:ASSET_TAG \
                                           tag_id:integer:unique:ASSET_TAG
bin/cake bake migration create_tags name:string:index \
                                    slug:string:unique \
                                    color \
                                    created \
                                    modified

# the users table will have an extra field you might not expect
# im going to eventually add github oauth to the app, so I want to track
# the user id if possible
bin/cake bake migration create_users name \
                                     email:string:index \
                                     password \
                                     github_id:integer:index \
                                     created \
                                     modified
```

We can now run our generated migrations:

```shell
bin/cake migrations migrate
```

This will create all of the above tables and two others:

- `jobs`: A simple background jobs table that is provided by the `josegonzalez/app` application skeleton. We'll get to this later.
- `phinxlog`: Used to keep track of migrations that have been executed.

## Baking my cake as fast as I can

The last step for today is generating some application defaults. We'll be using the [CrudView](/2015/12/03/generating-administrative-panels-with-crud-view/) plugin - and therefore [Bootstrap 3](https://getbootstrap.com/) - for the majority of our UI, and will be baking CrudView-compatible templates for things.

Lets start off by baking all of the tables and entities:

```shell
bin/cake bake model all
```

Next, lets bake some controllers and views for certain things (but not everything!):

```shell
bin/cake bake Controller Assets -t Crud
bin/cake bake Controller Categories -t Crud
bin/cake bake Controller Tags -t Crud
```

And now we'll turn on CrudView for the entire application. Simply change the `$isAdmin` property of `src/Controller/AppController.php` to `true`. This can be done on a per-controller basis, but as we are using CrudView everywhere, it doesn't hurt to turn it on universally.

And thats it for now. Why didn't we bake templates or certain tables:

- We need to add auth for users, and thats outside of what I wanted to accomplish today.
- We don't need a controller for join tables, nor for managing individual files (yet).
- Templating is done via the CrudView plugin. If you browse to `http://localhost:8765/categories`, you should see a simple crud-interface for categories. Ditto for `/assets` and `/tags`.

## What's next?

Since tying uploads to specific users and authentication is a bit core to my app, that will be what I tackle in my next post. I'll also go over that semi-mysterious `github_id` in a way that is sure to disappoint anyone who thinks I'm writing any OAuth code :)

Be sure to follow along via twitter on [@savant](https://twitter.com/savant). If you'd like to subscribe to this blog, you may follow the [rss feed here](/atom.xml). Also, all posts in the series will be conveniently linked on the sidebar of every post in the Media Manager series. Until next post, meow!
