---
  title:       "A quick rundown on Asset Compression"
  date:        2013-12-07 12:41
  description: "Using the AssetCompress plugin to render concatenated files is a cheap way to get better application performance"
  category:    CakePHP
  tags:
    - assets
    - asset_compress
    - CakeAdvent-2013
    - cakephp
  comments:    true
  sharing:     true
  published:   true
  layout:      post
  series:      CakeAdvent-2013
---

Asset compression is a small thing you can do to create more responsive applications. Rather than having your application serve up hundreds of smaller css and javascript files, you can serve up one or two and still retain the benefits of using separate files for different libraries in development.

## A How-to

> We'll be using the [AssetCompress](https://github.com/markstory/asset_compress) plugin from CakePHP Lead Developer Mark Story

You'll want to install the `asset_compress` plugin by Mark Story. In your `composer.json`, add the following:

```javascript
"markstory/asset_compress": "dev-master"
```

Then you'll want to run `composer update`. Next, ensure the plugin is loaded. It must be loaded *after* the global `Dispatcher.filters` in your `bootstrap.php`:

```php
<?php
// in app/Config/bootstrap.php
Configure::write('Dispatcher.filters', array(
    'AssetDispatcher',
    'CacheDispatcher'
));
CakePlugin::load('AssetCompress', array('bootstrap' => true));
?>
```

Finally, we'll need an `app/Config/asset_compress.ini` file to configure the plugin:

```ini
[General]
cacheConfig = false

[js]
cachePath = WEBROOT/cache_js/

[css]
cachePath = WEBROOT/cache_css/
```

The paths are used to cache the files on disk. Those paths *must* exist, so create them:

```bash
mkdir -p path/to/webroot/cache_js path/to/webroot/cache_css
```

Now we'll need to add a `js` section to our `asset_compress.ini`. This will be used to specify a list of libraries to handle as one build:

```ini
[externals.js]
files[] = zepto.js
files[] = underscore.js
files[] = backbone.js
```

When you want to include this build on your page, you can use the `AssetCompress` helper:

```php
<?php echo $this->AssetCompress->script('externals'); ?>
```

The name here refers to the build you created earler. Note that we do not use the extension when refering to it in your view.

Lets assume we want a custom filter. This filter should prepend some ascii text to the output:

```php
<?php
App::uses('AssetFilterInterface', 'AssetCompress.Lib');
class AsciiFilter implements AssetFilterInterface {
    public function output($file, $contents) {
        $art = <<<ART
/*
 (\_/)
(='.'=)
(")_(")
*/
ART
        return $art . $contents;
    }
}
?>
```

Next, we'll need to configure this for general usage. In the `[js]` section of your `asset_compress.ini`, add the following:

```ini
filters[] = AsciiFilter
```

Now when you reference it, it will contain the ascii art!

For production use, I recommend running the associated shell to generate css/js assets on deploy. For instance, you might do:

```bash
### clear existing assets
cake AssetCompress.AssetCompress clear

# build assets
cake AssetCompress.AssetCompress build
```

The above would build asset files in the defined directories for you. If your server - apache, cherokee, nginx - serves files on disk up before hitting PHP, then this should be an instant performance gain. Otherwise, the `asset_compress` plugin has the ability to generate these files dynamically on request.

## Wrap up

This was a short article meant to display what you *can* do with the `asset_compress` plugin. Hopefully you have this or a similar system setup in your CakePHP application. Happy baking!
