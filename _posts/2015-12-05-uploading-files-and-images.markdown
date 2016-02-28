---
  title:       "Uploading files and images with CakePHP 3"
  date:        2015-12-05 12:00
  description: "Silly hacks you can use in your cakephp applications"
  category:    cakephp
  tags:
    - cakeadvent-2015
    - cakephp
    - upload
    - files
    - images
  redirects:
    - /2015/12/04/uploading-files-and-images/
  comments:    true
  sharing:     true
  published:   true
  layout:      post
  series:      CakeAdvent-2015
---

I've been working for years on upload plugins. CakePHP 1.2 users might remember MeioUpload - such a good plugin, it did *all* the things. Which ended up being a bad move for maintainability. Something I took to heart when I worked on other alternatives, and when I finally wrote my [CakePHP Upload](https://github.com/josegonzalez/cakephp-upload) plugin. Until recently however, it supported only 2.x, and in this post-3.0 world, this just wouldn't cut it.

If you are using CakePHP 3, there have been a [few](https://github.com/WyriHaximus/FlyPie) [different](https://github.com/josbeir/image) [upload](https://github.com/davidyell/CakePHP3-Proffer) [plugins](https://github.com/Xety/Cake3-Upload). In my mind, the [Proffer](https://github.com/davidyell/CakePHP3-Proffer) plugin is the spiritual successor to the 2.x Upload plugin. If you need something more or less drop-in, I recommend looking into it. But this post isn't about the Proffer plugin, but rather the new version of my [own upload plugin](https://github.com/josegonzalez/cakephp-upload).

## Focus

One thing I hated about the old plugin version is the fact that I was manually handling image thumbnails. There are plenty [of](https://github.com/avalanche123/Imagine) [awesome](https://github.com/Gregwar/Image) [packages](https://github.com/Intervention/image) to handle this already. Upload did it in a hacky way, with interpolated php logic coming from a regex-parsed string. And only sometimes did it work. And anything advanced, like adding a watermark, was mostly impossible. Sad panda.

If you wanted to upload a file to S3, that was impossible without further work. Handling local files required a hacky behavior. Quite annoying when really the code changes should have been minimal.

The other thing is that it was hard to test the code. So many codepaths to handle complex logic that honestly didn't need to be there.

So with the 3.x plugin, I've resolved to the following:

- Only add code with 100% unit test coverage.
- Stick to file uploading only.
- Use external libraries for handling file storage.
- Remove code that wasn't strictly related to file uploading, like validation or image manipulation.
- Provide class-based entry points into the lifecycle of a file upload.

## Uploading a file

First install the thing:

```shell
composer require josegonzalez/cakephp-upload
```

and then load it in your `config/bootstrap.php`

```php
bin/cake plugin load Josegonzalez/Upload
```

Here is the database migration I am using in this example (more on migrations in a separate post).

```shell
# create the migration
bin/cake bake migration CreateUsers name username password role photo dir created modified

# apply it
bin/cake migrations migrate
```

Or use the following schema file directly:

```sql
CREATE TABLE `users` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(255) DEFAULT NULL,
  `username` varchar(255) NOT NULL,
  `password` varchar(255) NOT NULL,
  `role` varchar(255) NOT NULL,
  `photo` varchar(255) DEFAULT NULL,
  `dir` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `BY_USERNAME` (`username`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
```

This is a sample `UsersTable` that implements file uploading:

```php
<?php
namespace App\Model\Table;

use App\Model\Entity\User;
use Cake\ORM\Table;

class UsersTable extends Table
{

    public function initialize(array $config)
    {
        $this->table('users');
        $this->displayField('name');
        $this->primaryKey('id');

        // START: IMPORTANT PART HERE
        $this->addBehavior('Josegonzalez/Upload.Upload', [
            'photo',
        ]);
        // END: IMPORTANT PART ABOVE
    }
?>
```

Lastly, any forms where you will upload files will need to be modified with the following changes:

- `Form::create` must be of type file:
    ```
    <?= $this->Form->create($user, ['type' => file]) ?>
    ```
- `Form::input` for the field must be of type file:
    ```
    <?= echo $this->Form->input('photo', ['type' => 'file']); ?>
    ```
- You should hide/remove the extra fields. In particular, the plugin is automatically configured to use the `dir`, `type`, and `size` fields. These are configurable, but keep this in mind.

Pretty basic. It will upload anything to the path `webroot/files/Users/photo/ID`, and save metadata about the file to the `photo` field. We still have a few of the same config options, with many of the same defaults. For instance, we may wish to change the upload path to be outside of `webroot`:

```php
$this->addBehavior('Josegonzalez/Upload.Upload', [
    'photo' => [
        'path' => 'static{DS}{model}{DS}{field}{DS}{primaryKey}',
    ],
]);
```

We also save metadata about the file upload to three fields, `dir`, `size`, and `type`. We can customize those just as easily:

```php
$this->addBehavior('Josegonzalez/Upload.Upload', [
    'photo' => [
        'fields' => [
            'dir' => 'photo_dir',
            'size' => 'size_dir',
            'type' => 'type_dir',
        ],
    ],
]);
```

You can also upload multiple files:

```php
$this->addBehavior('Josegonzalez/Upload.Upload', [
    'photo',
    'video'
]);
```

## Customizing the file upload

CakePHP Upload does all the heavy-lifting using a new interface system. You can configure new classes to implement three key areas of file handling:

```php
$this->addBehavior('Josegonzalez/Upload.Upload', [
    'photo' => [
        // A pathProcessor handles both returning the basepath
        // as well as what the initial filename should be set to
        'pathProcessor' => 'Josegonzalez\Upload\File\Path\DefaultProcessor'

        // Allows you to create new files from the original source,
        // or possibly even modify/remove the original source file
        // from the upload process
        'transformer' => 'Josegonzalez\Upload\File\Transformer\DefaultTransformer'

        // Handles writing a file to disk... or S3... or Dropbox... or FTP... or /dev/null
        'writer' => 'Josegonzalez\Upload\File\Writer\DefaultWriter',
    ],
]);
```

For anyone wondering, the above system allows us to do any of the following:

- Handle arbitrary naming and pathing schemas
- Add or remove original files to the upload
- Extract video thumbnails
- Add watermarks to files
- Sanitize uploaded files
- Write those files to anywhere [Flysystem](http://flysystem.thephpleague.com/) supports

Want to create a thumbnail and upload both the original and your new file to S3? Install the AWS S3 Flysystem adapter:

```shell
composer require league/flysystem-aws-s3-v3
```

And the Imagine PHP image manipulation library:

```shell
composer require imagine/imagine
```

And follow along as we rock your socks off

```php
$client = \Aws\S3\S3Client::factory([
    'credentials' => [
        'key'    => 'your-key',
        'secret' => 'your-secret',
    ],
    'region' => 'your-region',
    'version' => 'latest',
]);
$adapter = new \League\Flysystem\AwsS3v3\AwsS3Adapter(
    $client,
    'your-bucket-name',
    'optional-prefix'
);

$this->addBehavior('Josegonzalez/Upload.Upload', [
    'photo' => [
        // Ensure the default filesystem writer writes using
        // our S3 adapter
        'filesystem' => [
            'adapter' => $adapter,
        ],

        // This can also be in a class that implements
        // the TransformerInterface or any callable type.
        'transformer' => function (\Cake\Datasource\RepositoryInterface $table, \Cake\Datasource\EntityInterface $entity, $data, $field, $settings) {
            // get the extension from the file
            // there could be better ways to do this, and it will fail
            // if the file has no extension
            $extension = pathinfo($data['name'], PATHINFO_EXTENSION);

            // Store the thumbnail in a temporary file
            $tmp = tempnam(sys_get_temp_dir(), 'upload') . '.' . $extension;

            // Use the Imagine library to DO THE THING
            $size = new \Imagine\Image\Box(40, 40);
            $mode = \Imagine\Image\ImageInterface::THUMBNAIL_INSET;
            $imagine = new \Imagine\Gd\Imagine();

            // Save that modified file to our temp file
            $imagine->open($data['tmp_name'])
                    ->thumbnail($size, $mode)
                    ->save($tmp);

            // Now return the original *and* the thumbnail
            return [
                $data['tmp_name'] => $data['name'],
                $tmp => 'thumbnail-' . $data['name'],
            ];
        },
    ],
]);
```

A list of methods needed to implement the proper interfaces [are here](https://cakephp-upload.readthedocs.org/en/latest/interfaces.html).

## Things yet to do

One thing that is sorely missing is upload file validation. Yes, you're going to have to write these on your own. The Proffer plugin has these available, though in my mind the validation rules should be in their own plugin so *all* upload plugins can benefit by just adding a `require` statement to their `composer.json`. Also, I'm lazy, and didn't want to write a custom Validator class.

Documentation is a bit sparse - the above docs are the first to show exactly how powerful the plugin can be - but that will be ameliorated over time.

## A note of caution

One thing I'd like to stress is that the less you do during a page request, the faster your response time will be and the more likely your users will use your site. Here's a [helpful post](http://searchengineland.com/googles-push-to-speed-up-your-web-site-42177) on just how important that be to numbers like, idk, user retention and revenue.

Given that information, I'd caution you against handling image manipulation etc. within a web request. This will work fine for some websites and internal administrative tools, but at some point you're going to have to bite the bullet and refactor this code (and potentially even move the image uploading to outside of PHP entirely!). If only there was a way of combining file uploading and background processing...

Until next time!
