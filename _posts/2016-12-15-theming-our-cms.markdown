---
  title:       "Theming our CMS"
  date:        2016-12-15 03:20
  description: "Part 15 of a series of posts that will help you build out a personal CMS"
  category:    cakephp
  tags:
    - themes
    - views
    - cakeadvent-2016
    - cakephp
  comments:    true
  sharing:     true
  published:   true
  layout:      post
  disable_advertisement: true
  series:      CakeAdvent-2016
---

A friend of mine asked for a custom website, so here I am, writing a custom cms. I know, there are plenty of systems out there that would handle his needs, but it's also a good excuse to play around with CakePHP 3, so here we are.

> For the lazy, the codebase we'll be working on will be available on [GitHub](https://github.com/josegonzalez/cakeadvent-2016). I will be pushing each set of changes on the date when each blog post in this series is published. No cheating!

## Setting up a Theme

As much as I love the default CakePHP css, I'd like the default installation to look a bit different. To do so, I'll distribute a custom theme with the Cms called `DefaultTheme`.

In CakePHP 3, themes are distributed as plugins. This makes it pretty easy to create an installer or similar for your themes, as well as scaffold them :)

```shell
bin/cake bake plugin DefaultTheme -f
```

We've scaffolded a theme, but we'll want to modify a few things:

- You remove the `plugins/DefaultTheme/config/routes.php` file as we wont need it
- Remove `plugins/DefaultTheme/src` as we won't be using the AppController that is created
- Modify your `config/bootstrap.php` to *not* load the plugin's bootstrap or routes. It should look like so:

    Plugin::load('DefaultTheme');

To load a theme, we'll modify our `AppView` - located in `src/View/AppView.php` - to be the following:


```php
public function initialize()
{
    $this->theme('DefaultTheme');
}
```

Let's save our work and move on:

```shell
git add composer.json config/bootstrap.php plugins/DefaultTheme src/View/AppView.php
git commit -m "Add a dummy DefaultTheme"
```

## CakePHP Theme internals

CakePHP themes are a bit weird. Here are some general guidelines:

- Using a theme will inject it's template files into the cake template search paths *first*. If a file is not found in a theme, it will default to any other search paths (so the main `src/Template` dir, or other plugins).
- General template files, elements, and layouts can all be overriden from a theme.
- Assets referenced from a theme will be loaded from that theme. If they aren't found, CakePHP will try and load them from the main repo.
- Assets - css, images, javascript files - will be proxied via PHP unless you symlink the theme's webroot directory into place.
- There is no way to override a file provided by a theme.

I'm not going to include all of my theme code, but I will show some interesting bits.

> The theme is based on the [Centrarium Jekyll Theme](https://github.com/bencentra/centrarium), and uses a logo by Kassy from [sketchport](https://www.sketchport.com/drawing/1782016/camera).

I'll commit my theme so you can take a look at the changes.

```shell
git add plugins/DefaultTheme
git commit -m "Implement DefaultTheme"
```

### Custom Helper Templates

In CakePHP 3, all helpers output html fragments based on a simple templating language. It uses string fragments to specify what the "template" should be for an html element, such as a `link` or `image` tag. It's used throughout CakePHP, which is good as in our case, we're going to modify what pagination looks like.

> Templates use `{% raw %}{{var}}{% endraw %}` style placeholders. It is important to not add any spaces around the `{% raw %}{{}}{% endraw %}` or the replacements will not work.

Here is what I've placed in my theme's `home.ctp` to customize what the `PaginatorHelper` uses for building next/previous links:

```php
<?php
$this->Paginator->templates([
    'nextDisabled' => implode(' ', [
        '<span class="fa-stack fa-lg">',
            '<i class="fa fa-square fa-stack-2x"></i>',
            '<i class="fa fa-angle-double-right fa-stack-1x fa-inverse"></i>',
        '</span>',
    ]),
    'nextActive' => implode(' ', [
        '<a rel="prev" href="{{url}}">',
            '<span class="fa-stack fa-lg">',
                '<i class="fa fa-square fa-stack-2x"></i>',
                '<i class="fa fa-angle-double-right fa-stack-1x fa-inverse"></i>',
            '</span>',
        '</a>',
    ]),
    'prevDisabled' => implode(' ', [
        '<span class="fa-stack fa-lg">',
            '<i class="fa fa-square fa-stack-2x"></i>',
            '<i class="fa fa-angle-double-left fa-stack-1x fa-inverse"></i>',
        '</span>',
    ]),
    'prevActive' => implode(' ', [
        '<a rel="prev" href="{{url}}">',
            '<span class="fa-stack fa-lg">',
                '<i class="fa fa-square fa-stack-2x"></i>',
                '<i class="fa fa-angle-double-left fa-stack-1x fa-inverse"></i>',
            '</span>',
        '</a>',
    ]),
]);
```

You can also customize templates for the `FormHelper` and `HtmlHelper`.

### Custom Theme Elements

I've overriden what the post types will display as in my theme. If I hadn't, we'd be using the default elements from the respective post type plugin. Here is what my `plugins/DefaultTheme/src/Template/Element/post_type/photo-index.ctp` looks like:

```php
<h2><?= $this->Html->link($post->get('title'), $post->get('url')) ?></h2>
<section class="post-meta">
    <div class="post-date"><?= $this->Time->nice($post->get('published_date')) ?></div>
</section>
<section class="post-excerpt" itemprop="description">
    <?= $this->Html->image('../' . $post->get('photo_path')) ?>
</section>
```

Note that my image link works as normal, and displays the original post image as desired.

### Theme Links

One thing I'm doing in my theme is linking to custom pages, such as `/about`, and also using the post urls as links. These aren't currently routed by the CMS, so we'll want to handle that next.

---

> For those that may just want to ensure their codebase matches what has been done so far, the codebase is available on GitHub and tagged as [0.0.15](https://github.com/josegonzalez/cakeadvent-2016/tree/0.0.15).

The frontend of our site is in decent shape, though now we have some routing work to do. None of our custom post types have their own user-reachable urls, so in our next post, we'll update the CakePHP routing to understand our routing schema.

Be sure to follow along via twitter on [@savant](https://twitter.com/savant). If you'd like to subscribe to this blog, you may follow the [rss feed here](/atom.xml). Also, all posts in the series will be conveniently linked on the sidebar of every post in the 2016 CakeAdvent Calendar. Come back tomorrow for more delicious content.
