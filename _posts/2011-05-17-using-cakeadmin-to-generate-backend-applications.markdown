---
  title: Using CakeAdmin to generate backend applications
  category: CakePHP
  tags:
    - admin
    - cake_admin
    - cakephp-1.3
  description: CakeAdmin is a CakePHP 1.3 plugin for building web application backends quickly and easily. It is most analogous to running `cake bake` which generating your basic application structure with a series of questions.
  comments:    true
  sharing:     true
  published:   true
  layout:      post
---

[CakeAdmin](https://github.com/josegonzalez/cake_admin) is a CakePHP 1.3 plugin for building web application backends quickly and easily. It is most analogous to running `cake bake` which generating your basic application structure with a series of questions.

{% pullquote %}
Future development may allow for rollout of CakeAdmin classes with built-in schemas, or in conjunction with migrations.
{% endpullquote %}

[CakeAdmin](https://github.com/josegonzalez/cake_admin) differs from the Bake tool in that it allows the developer to centralize this set of answers into a single file for every model. It still requires the sql tables to be available for each model, but it doesn't require that you re-answer every single question each time you'd like to regenerate your application.

[CakeAdmin](https://github.com/josegonzalez/cake_admin) also allows you to specify special properties for both Models, Views and Controllers, depending upon the configuration file you specify. Because a given backend is generated through composition, you can specify all the behavior configuration, special component instructions, and any other related data quickly and easily. As well, [CakeAdmin](https://github.com/josegonzalez/cake_admin) separates the built files from your regular application and places them into a plugin so there isn't any potential weird interaction between them, meaning your backend application logic can stay nicely removed from your frontend application.

[CakeAdmin](https://github.com/josegonzalez/cake_admin) works by specifying a series of properties on a `*CakeAdmin` class. For example, we might have a `PostCakeAdmin` class - available in `app/libs/admin/post_cake_admin.php` - that builds an administrative section for your `Post` model. The simplest example is below:

```php
class PostCakeAdmin extends CakeAdmin {
}
```

The above admin file would create the `index`, `add`, `edit`, and `delete` actions for your backend in `app/plugins/admin/`. This means you would be able to access it at `localhost/admin/posts`, without having to turn on prefix routing. For those who wish to use prefix routing as well as `cake_admin`, it would be possible to specify additional routes to ensure everything in your new plugin works.

It's also possible to specify special behaviors on a given `*CakeAdmin` class. Given a Post model that would normally have a `photo` field storing a photo name, we might have the following `PostCakeAdmin` class:

```php
class PostCakeAdmin extends CakeAdmin {
    var $actsAs = array('Upload.Upload' => array('photo'));
}
```

The above assumes we're using the [Upload Plugin](https://github.com/josegonzalez/upload), but we could extend this idea to pretty much any other behavior. We would still need to modify our forms to ensure that the form fields are correct for this particular plugin like so:

```php
class PostCakeAdmin extends CakeAdmin {
    var $actsAs = array('Upload.Upload' => array('photo'));
    var $actions = array(
        'edit' => array(
            'type' => 'edit',
            'config' => array(
                array(
                    'fields' => array(
                        'title',
                        'photo' => array(
                            'type' => 'file',
                        ),
                        'active',
                    ),
                    'formType' => 'file',
                ),
            ),
        ),
        'add' => array(
            'type' => 'add',
            'config' => array(
                array(
                    'fields' => array(
                        'title',
                        'photo' => array('type' => 'file'),
                        'active',
                    ),
                    'formType' => 'file',
                ),
            ),
        )
    );
}
```

{% pullquote %}
Built-in actions include index, add, edit, delete, view, history, changelog. Since each action has a very specific, and likely peculiar configuration setup, you may want to delve further into each class for more information.
{% endpullquote %}

You'll notice we specify both the formType, as well as fields to include in a particular config. When we want to give specific instructions to an action, we do it by specifying an `actionAlias` mapping to an `actionConfig`. The `actionConfig` determines the type of the action, whether it is `enabled` or not - `enabled` is set to true for the `[index, add, edit, delete]` actions by default - as well as a `config` array. If any of these is missing, the action defaults are merged in and we can continue processing, so it is not necessary to specify them for every action. It is also important to note that the format of these actions is different depending upon your specific needs

So why would you want to use [CakeAdmin](https://github.com/josegonzalez/cake_admin)? It's primarily for building boring backend applications. Sometimes your application needs a bit of CRUD, regardless of how custom it is. I've spent many hours working on CRUD-like utilities at work for [SeatGeek](http://seatgeek.com), and having something like [CakeAdmin](https://github.com/josegonzalez/cake_admin) would have been a lifesaver.

[CakeAdmin](https://github.com/josegonzalez/cake_admin) is also meant to facilitate future admin panel development. There are lots of things it does not yet support - TreeBehavior, TranslateBehavior - and items that I'd like to see implemented - fully Ajax forms, Model Inlines - so the road ahead might be quite bumpy. It's important to note that you can implement your own custom actions now, like a Gallery action, or a Revision Viewer, so in a sense it is production ready. It's been used in at least 2 of my own projects to some success, and I am aware of a few people currently looking at it as an option.

[CakeAdmin](https://github.com/josegonzalez/cake_admin) isn't for everyone, but it's definitely already a great alternative to the built-in BakeTool. Try it out, leave comments, open bugs, contribute to the built-in actions, make cash off of it. Hope you enjoy it as much as I do.
