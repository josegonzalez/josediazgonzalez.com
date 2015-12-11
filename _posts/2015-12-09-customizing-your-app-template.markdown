---
  title:       "Customizing your Application Template"
  date:        2015-12-09 12:00
  description: "Silly hacks you can use in your cakephp applications"
  category:    cakephp
  tags:
    - cakeadvent-2015
    - cakephp
    - composer
    - create-project
  comments:    true
  sharing:     true
  published:   true
  layout:      post
  series:      CakeAdvent-2015
---

CakePHP has long had the ability to generate new projects via the `bake` command:

```shell
// my custom cat project
cake bake project camila
```

With the above command, CakePHP would scaffold out all the necessary directories and files for a new project (`AppModel`, `AppController`, configuration files, etc.). You could even customize this using a [bake skeleton](http://book.cakephp.org/2.0/en/console-and-shells/code-generation-with-bake.html#for-baking-custom-projects):

```shell
// be sure to copy in my cat project instead
cake bake project camila --skel Console/Templates/cat
```

In CakePHP 3, this feature of bake has mostly gone away in favor of using `composer` to handle scaffolding. When starting a new project, you typically do something like:

```shell
composer create-project --prefer-dist cakephp/app camila
```

Composer's `create-project` command is great for scaffolding out new projects and is used for a variety of things:

- Framework-specific application repos
- Framework-specific plugin modules
- Generic composer packages

The great thing about this command is that the "skeletons" are in all actually composer packages. This means it is extremely easy to use your normal distribution methods to release new versions of the package, something the CakePHP project has done with it's [cakephp/app](https://github.com/cakephp/app) repository.

Now, as a side-effect of this, you can _*also*_ fork any existing composer skeleton and add your own customizations. For instance, lets say we wanted to have a composer skeleton with the following plugins installed automatically:

- [josegonzalez/upload](https://github.com/josegonzalez/cakephp-upload)
- [friendsofcake/crud](https://github.com/friendsofcake/crud)
- [friendsofcake/crud-view](https://github.com/friendsofcake/crud-view)
- [league/fractal](https://github.com/thephpleague/fractal)
- [usemuffin/trash](https://github.com/usemuffin/trash)

We can simply do the following:

1. Fork the [cakephp/app](https://github.com/cakephp/app) repository on github.
2. Change the name in the fork's composer.json to `myname/app`.
3. Add any custom requirements to the `composer.json`.
4. Make a new tag/release on github.
5. Add it to [packagist.org](https://packagist.org)

Pretty simple. We can now use this project as a baseline for all of our new CakePHP projects:

```shell
composer create-project --prefer-dist myname/app camila
```

Apart from adding custom plugins, one thing you may want to look is customizing the initial project files. For instance, if you find yourself constantly adding certain helper classes, or modifying how configuration is loaded, this is a good chance to improve the base state of your initial applications.

As every project is slightly different, please try and keep application-specific enhancements to a minimum, as they may only serve as a hindrance when using your skeleton. No one wants to setup an app and then spend an hour deleting useless code :)

For those of you who are interested in such a project, [here is an advanced skeleton](https://github.com/loadsys/CakePHP-Skeleton) from the good folks at [Loadsys Web Strategies](https://www.loadsys.com/).
