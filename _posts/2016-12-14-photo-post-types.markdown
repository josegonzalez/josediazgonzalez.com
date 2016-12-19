---
  title:       "Photo Post Types"
  date:        2016-12-14 01:37
  description: "Part 14 of a series of posts that will help you build out a personal CMS"
  category:    cakephp
  tags:
    - uploads
    - cakeadvent-2016
    - cakephp
  comments:    true
  sharing:     true
  published:   true
  layout:      post
  disable_advertisement: true
  series:      CakeAdvent-2016
  og_image:    /images/2016/12/14/baby-upload.png
---

A friend of mine asked for a custom website, so here I am, writing a custom cms. I know, there are plenty of systems out there that would handle his needs, but it's also a good excuse to play around with CakePHP 3, so here we are.

> For the lazy, the codebase we'll be working on will be available on [GitHub](https://github.com/josegonzalez/cakeadvent-2016). I will be pushing each set of changes on the date when each blog post in this series is published. No cheating!

## Scaffolding the PhotoPostType plugin

For our photo posts, here are the extra fields we are tracking:

- `photo`: The name the user used for the image being uploaded
- `photo_dir`: Path on disk - relative to www_root - where the file will be stored
- `photo_path`: Path on disk - relative to www_root - where the file will be stored *including* a sanitized filename

We'll also want to validate that our photo is a valid image before attempting to upload it. Finally, we need to upload the image before saving the post itself. Let's start by baking a `PhotoPostType` plugin, which should also update our `composer.json` to update code load paths.

```shell
bin/cake bake plugin PhotoPostType -f
```

Next, we'll create a `plugins/PhotoPostType/config/bootstrap.php` to load our plugin post type.

```php
<?php
use Cake\Event\Event;
use Cake\Event\EventManager;

EventManager::instance()->on('Posts.PostTypes.get', function (Event $event) {
  // The key is the Plugin name and the class
  // The value is what you want to display in the ui
  $event->subject->postTypes['PhotoPostType.PhotoPostType'] = 'blog';
});
```

> You can remove the `plugins/PhotoPostType/config/routes.php` file as we wont need it

We'll want to ensure that the bootstrap file is loaded for this plugin, so check to ensure that your `config/bootstrap.php` has the following `Plugin::load` line (update it if need be):

```php
Plugin::load('PhotoPostType', ['bootstrap' => true, 'routes' => false]);
```

Remember to save your work!

```shell
git add composer.json config/bootstrap.php plugins/PhotoPostType
git commit -m "Scaffold the PhotoPostType plugin"
```

## PhotoPostType form fields and validation

We will now need the `PostType` class that contains the code for our form. Here are the initial contents of `plugins/PhotoPostType/PostType/PhotoPostType.php`:

```php
<?php
namespace PhotoPostType\PostType;

use App\PostType\AbstractPostType;
use Cake\Form\Schema;
use Cake\Validation\Validator;

class PhotoPostType extends AbstractPostType
{
    protected function _buildSchema(Schema $schema)
    {
        $schema = parent::_buildSchema($schema);
        $schema->addField('photo', ['type' => 'file']);
        $schema->addField('photo_dir', ['type' => 'hidden']);
        $schema->addField('photo_path', ['type' => 'hidden']);
        return $schema;
    }

    protected function _buildValidator(Validator $validator)
    {
        $validator = parent::_buildValidator($validator);
        $validator->add('photo', 'valid-image', [
            'rule' => ['uploadedFile', [
                'types' => [
                    'image/bmp',
                    'image/gif',
                    'image/jpeg',
                    'image/pjpeg',
                    'image/png',
                    'image/x-windows-bmp',
                    'image/x-png',
                ],
                'optional' => true,
            ]],
            'message' => 'The uploaded photo was not a valid image'
        ]);
        return $validator;
    }
}
```

Pretty simple. We're adding a few fields for the form - two of which are hidden - and then adding a validation rule to allow *only* images. Seems pretty straightforward. I'll also commit my changes here.

```shell
git add plugins/PhotoPostType/src/PostType/PhotoPostType.php
git commit -m "Initial form display for photo post types"
```

### Handling file uploads

We're going to need to actually write the files to disk. To do this, I'm going to use the wonderful [League/Flysystem](http://flysystem.thephpleague.com/) library. This will abstract actual file writing for me, and also potentially allow me to upload images to non-local storage.

All the file upload logic begins in our `PhotoPostType::transformData()` method. Here is the body of that method:

```php
public function transformData($data)
{
    $photoExtension = pathinfo($data['photo']['name'], PATHINFO_EXTENSION);
    $photoDirectory  = 'files/Posts/photo/' . uniqid();
    $photoFilename = uniqid() . '.' . $photoExtension;
    $photoPath $photoDirectory . '/' . $photoFilename
    $postAttributes = [
        ['name' => 'photo_dir', 'value' => $photoDirectory],
        ['name' => 'photo', 'value' => $data['photo']['name']],
        ['name' => 'photo_path', 'value' => $photoPath],
    ];

    $success = $this->writeFile($data['photo'], $photoPath);
    unset($data['photo'], $data['photo_dir'], $data['photo_path'] $data['post_attributes']);
    if (!$success) {
        return $data;
    }

    $data['post_attributes'] = $postAttributes;

    return $data;
}
```

Let's walk through this:

- I get the photo extension using the `pathinfo` method. This might fail if there was no original extension on the uploaded file, so in a future revision, we'll want to properly detect the mimetype and remap the extension, but this is good for now.
- I'm using `uniqid` to get a filepath on disk. I won't currently be handling vacuuming old file uploads, so we want to ensure we don't overwrite existing files. A good alternative would be to use `Text::uuid()`, but I don't expect any issues for my use case.
- We'll need to write the file to disk, and that logic is shown elsewhere.
- If the file is saved successfully, we add the extra post attributes, and otherwise just return as is. We would be better suited in handling this error, but I'll leave that up to the reader.

What does file uploading look like? First, add the following `use` calls to the top of the class for classes that will be, well, used by our file uploading mechanism:

```php
use League\Flysystem\Adapter\Local;
use League\Flysystem\AdapterInterface;
use League\Flysystem\FileNotFoundException;
use League\Flysystem\Filesystem;
use League\Flysystem\FilesystemInterface;
```

Here is the `PhotoPostType::writeFile()` method (and related helper methods):

```php
protected function writeFile(array $filedata, $filepath)
{
    $success = false;
    $stream = @fopen($filedata['tmp_name'], 'r');
    if ($stream === false) {
        return $success;
    }

    $filesystem = $this->filesystem();
    $success = $filesystem->writeStream($filepath, $stream);
    fclose($stream);

    return $success;
}

protected function filesystem()
{
    $adapter = new Local(WWW_ROOT);
    $filesystem = new Filesystem($adapter, [
        'visibility' => AdapterInterface::VISIBILITY_PUBLIC
    ]);

    return $filesystem;
}
```

A bit to go through, but a pretty-straightforward read I think. Some implementation notes:

- I typically use streams for writing to flysystem. You can also write content directly, but as the file already exists locally, using a file stream is the most natural.
- If we can't open the temp file, we fail the write.
- I've used an extra method to get the `Filesystem` object, which will allow me to mock the filesystem for tests.

Neat! Let's save our progress.

```shell
git add plugins/PhotoPostType/src/PostType/PhotoPostType.php
git commit -m "Handle file uploads for the photo post type"
```

### Displaying Photos in the frontend

Our default `src/Template/Element/post_type/photo-index.ctp` and `src/Template/Element/post_type/photo-view.ctp` template files are pretty trivial. I'm simply going to show the post type and then a link to the image in each:

```php
<h3><?= $post->get('title') ?></h3>
<div>
    <?= $this->Html->image('../' . $post->get('photo_path')) ?>
</div>
```

Here is what it looks like (using my favorite picture of [Chris Hartjes](https://twitter.com/grmpyprogrammer)):

![baby image](/images/2016/12/14/baby-upload.png)

Remember to commit your new files.

```shell
git add plugins/PhotoPostType/src/Template/Element/post_type/photo-index.ctp plugins/PhotoPostType/src/Template/Element/post_type/photo-view.ctp
git commit -m "Add default photo templates"
```

---

> For those that may just want to ensure their codebase matches what has been done so far, the codebase is available on GitHub and tagged as [0.0.14](https://github.com/josegonzalez/cakeadvent-2016/tree/0.0.14).

We now have our custom photo post type, and it's pretty bad-ass. While the admin ui could use some work - how do you know you've already uploaded an image? - we're pretty far along.

Be sure to follow along via twitter on [@savant](https://twitter.com/savant). If you'd like to subscribe to this blog, you may follow the [rss feed here](/atom.xml). Also, all posts in the series will be conveniently linked on the sidebar of every post in the 2016 CakeAdvent Calendar. Come back tomorrow for more delicious content.
