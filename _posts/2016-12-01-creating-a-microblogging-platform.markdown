---
  title:       "Creating a microblogging platform"
  date:        2016-12-01 01:56
  description: "Part 1 of a series of posts that will help you build out a personal CMS"
  category:    cakephp
  tags:
    - cakeadvent-2016
    - cakephp
  comments:    true
  sharing:     true
  published:   true
  layout:      post
  disable_advertisement: true
  series:      CakeAdvent-2016
---

A friend of mine asked for a custom website, so here I am, writing a custom cms. I know, there are plenty of systems out there that would handle their needs, but it's also a good excuse to play around with CakePHP 3, so here we are.

> For the lazy, the codebase we'll be working on will be available on [GitHub](https://github.com/josegonzalez/cakeadvent-2016). I will be pushing each set of changes on the date when each blog post in this series is published. No cheating!

## Setup

To follow this series of tutorials, you'll need at least the following setup:

- PHP 5.5.9+: I am running PHP 7.0.12 locally
- Composer: I've installed this via `homebrew` on my mac.
- A supported CakePHP SQL Database: I am testing against both Postgres and MySQL. YMMV.
- git: I've installed this via `homebrew` on my mac.

If you have none of these, you'll want to use the [friendsofcake/vagrant-chef](https://github.com/friendsofcake/vagrant-chef) setup. It has support for multiple PHP applications, as well as various datastores/utilities, and is probably the easiest setup to get going. Follow the instructions in the readme if you have any further questions.

## Baking the App

Lets start by baking the app! Most CakePHP projects start out by using the official cakephp/app going to use my own [josegonzalez/app](https://github.com/josegonzalez/app) composer project skeleton. It has a few goodies I'll be using in the application.

```shell
composer create-project --no-interaction --prefer-dist josegonzalez/app calico
```

A few things!

- I've named my blog platform `calico`. You can name yours lollipop if you'd like. Calico suits me pretty well.
- I'm using the `--no-interaction` flag to create the new project. If you omit this, the `composer` command may ask you questions. For now, I am assuming that the defaults are fine.
- I've customized the project skeleton by specifying `josegonzalez/app`. Changing this will change your skeleton base.

Lets save our new application in a git repository.

```shell
cd calico
git init
git add .
git commit -m "Initial commit"
```

> All further shell commands are assumed to be running within the application folder. In this case, that will be `calico`.

## Configuring our app

In my application skeleton, all configuration is done via environment variables. This allows us to change any config value at runtime without necessitating a full application deploy. It will also allow us to specify different environments both locally, as well as once the application has been deployed to a server. All config is stored in the `config/.env.default` file, though it is highly recommended that you customize it in a `config/.env` file. Lets do that:

```shell
cp config/.env.default config/.env
```

> The `config/.env` file is git-ignored, meaning it will not be tracked by git and cannot be committed. To see what else is git-ignored, check out the `.gitignore` file in your repository base.

I'm going to change one thing in my `config/.env`, and that is the `APP_NAME` variable. I've changed mine to `calico`, because that is what my application is called. The other environment variables can be changed at will, and - through a few small modifications to the base app project - are automatically picked up by CakePHP.

## Creating our initial database tables

Before we continue, you'll want to create a database for your application. By default, the app skeleton will name the database after your `APP_NAME` variable. For my application, the following databases were created:

- `calico`
- `calico_test`

You can configure the `DATABASE_URL` environment variable in the `config/.env` file to change this default.

> The default username and password are also set here to the normal CakePHP defaults. I created both of these on my server, though you can modify these - and the other sections of that environment variable - to suit your needs.

Now that you have a database setup, we'll want a few tables. After speaking with my friend, I've decided upon the following initial schema.

- Users hasMany Posts
- Posts belongsTo Users
- Posts hasMany PostAttributes
- PostAttributes belongsTo Posts

Why am I going for an extra table to store post attributes?

- CakePHP does not support native JSON values in the ORM. It is totally possible to use JSON, but I don't get any native database enhancements (yet)
- The CMS is a bit of a tumblog, and I don't completely know what post types I'll be creating. I can optimize this later if need be, but I doubt it will be a problem.
- It lets me play with the ORM a bit more.


We'll be generating migration files using the `cake bake` cli tool. Migrations can be used to version our database locally in PHP files, allowing us to apply them as necessary:

```shell
bin/cake bake migration create_posts user_id:integer:index type:string:index url:string:index status:index created modified
sleep 1
bin/cake bake migration create_post_attributes post_id:integer:index name:string[100] value:text
sleep 1
bin/cake bake migration create_users email:string:index password:string avatar:string avatar_dir:string created modified
```

> Why Sleep? We sleep because each migration uses the current timestamp as the unique identifier. This is a limitation of phinx, the library in use for migrations. By adding a sleep in between each command, we simulate running each command at a different timestamp, and therefore give them unique identifiers.

Seems legit. Once you run those commands, you'll have three migration files in `config/Migrations`. We can execute these against our database using the following `cake` cli command:

```shell
bin/cake migrations migrate
```

If you open up your database, you'll see our three tables were created by the above command, as well as a fourth `phinx` table. This table is used to figure out which migrations were already run.

Lets commit these changes:

```shell
git add config/Migrations
git commit -m "Added migrations for posts, post_attributes, and users"
```

## Baking the app

This bit is pretty trivial. CakePHP has long offered a `bake` tool that can be used to autogenerate files for your application. CakePHP includes it's own bake templates that have quite a bit of functionality "baked" in, but we'll be using the `Crud` templates.

What is `Crud`? Think of Crud as a programmatic bake. It allows us to provide the same defaults as `bake` would, but *also* provides a programmable interface to editing those defaults. In the past, rebaking a file would have ended up destroying most of your customizations. Crud allows you to reuse the default actions in your controllers and views with all the power of an actual programming language. It's a bit hard to explain, so just assume I know what I'm talking about and we'll hopefully get through this.

To bake using crud templates, we'll run the following commands:

```shell
bin/cake bake all posts --theme Crud
bin/cake bake all post_attributes --theme Crud
bin/cake bake all users --theme Crud
```

If you run `git status` at this point, the following files and directories will show up:

```
src/Controller/PostAttributesController.php
src/Controller/PostsController.php
src/Controller/UsersController.php
src/Model/Entity/Post.php
src/Model/Entity/PostAttribute.php
src/Model/Entity/User.php
src/Model/Table/PostAttributesTable.php
src/Model/Table/PostsTable.php
src/Model/Table/UsersTable.php
src/Template/PostAttributes/
src/Template/Posts/
src/Template/Users/
tests/Fixture/PostAttributesFixture.php
tests/Fixture/PostsFixture.php
tests/Fixture/UsersFixture.php
tests/TestCase/Controller/PostAttributesControllerTest.php
tests/TestCase/Controller/PostsControllerTest.php
tests/TestCase/Controller/UsersControllerTest.php
tests/TestCase/Model/Table/
```

Lots of gunk here. Lets explain them all before continuing:

- `src/Controller`: These files are where you'll be adding most entrypoints to the application. If you open any of these up, they'll be largely empty, as they will be inheriting from the `AppController` located in `src/Controller/AppController.php`. Don't worry too much about these, we'll dig into them further in a bit.
- `src/Model/Entity`: Handles some minimal logic concerning individual records in your database. I usually put "helper" code in here - date-time formatting, pretty-printed titles - in these classes.
- `src/Model/Table`: Business logic *can* go here. I generally place complex find queries (select statements) here. You can also place validation rules here, as well as configure the Table to have the correct behaviors (decorator classes that change/enhance functionality).
- `src/Template`: In CakePHP 2, we placed `.ctp` (cake templates) files in the View directory. In CakePHP 3, the View folder is reserved for Helpers and View classes, while cake template files go in `src/Template`. It's a bit cleaner, and also lets you use `View` and `Helper` as table names.
- `tests/Fixture`: The classes here contain sample data that can be inserted into our test database during testing.
- `tests/TestCase`: Test classes! They are mostly stubs, because we haven't written any real code yet.

I'm going to add all these files and call it a night. My friend said they have a few weeks before they need their site, so taking it slow works for me :)


```shell
git add src/Controller src/Model/Entity src/Model/Table src/Template tests/Fixture tests/TestCase
git commit -m "Add baked files for initial application"
```

Yay!

--

> For those that may just want to ensure their codebase matches what has been done so far, the codebase is available on GitHub and tagged as [0.0.1](https://github.com/josegonzalez/cakeadvent-2016/tree/0.0.1).

What is next? While you can certainly go in and create any records you'd like at this time, we're going to want to lock down our database. Thus, our next target will be general user management, including a forgot password flow and modifying their personal details. We'll be covering the above topic in the next installment of CakeAdvent 2016.

Be sure to follow along via twitter on [@savant](https://twitter.com/savant). If you'd like to subscribe to this blog, you may follow the [rss feed here](/atom.xml). Also, all posts in the series will be conveniently linked on the sidebar of every post in the 2016 CakeAdvent Calendar. Come back tomorrow for more delicious content.
