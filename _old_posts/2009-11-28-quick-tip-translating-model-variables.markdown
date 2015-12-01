---
  title:       "Quick Tip - Translating Model Variables"
  description: Translating CakePHP Model variables and validation rules isn't straight-forward to new developers. However, it is possible through the use of the class constructor.
  category:    cakephp
  tags:
    - cakephp
    - quicktip
    - internationalization
    - translation
    - model
    - cakephp 1.2
    - cakephp 1.3
  comments:    true
  sharing:     true
  published:   true
  layout:      post
---

While working on a now [defunct cms](http://github.com/josegonzalez/marcyavenue/), I was attempting to internationalize model validation messages. I thought I had a pretty good idea as to how to internationalize those messages. Usually, you do the following to any string in CakePHP:

```php
__('encapsulate string in this convenient function');
```

And then run the following shell command:

```shell
cake i18n initdb
cake i18n extract
```

That should somehow generate .pot files, which is where CakePHP will grab translations.

So I did the following to my rules:

```php
class Category extends AppModel {
    var $name = 'Category';
    function __construct() {
        $this->validate = array(
            'title' => array(
                'notempty' => array(
                    'rule' => array('notempty'),
                    'message' => __('cannot be left empty', true)
                ),
            ),
        );
        $this->visibilities = array(
            'published' => __('Published', true),
            'private' => __('Private', true),
            'password' => __('Password Protected', true),
        );
    }
}
```

*Don't do that! It will break the entire application!* The error message will be something like the following:

```generic
Fatal error: Call to a member function trigger() on a non-object in cake/libs/model/model.php on line 2057
```

Not very helpful.

It turns out I forgot to call the parent Model::__construct() function when redefining the constructor. So I did the following:

```php
class Category extends AppModel {
    var $name = 'Category';
    function __construct($id = false, $table = null, $ds = null) {
        $this->validate = array(
            'title' => array(
                'notempty' => array(
                    'rule' => array('notempty'),
                    'message' => __('cannot be left empty', true)
                ),
            ),
        );
        $this->visibilities = array(
            'published' => __('Published', true),
            'private' => __('Private', true),
            'password' => __('Password Protected', true),
        );

        parent::__construct($id, $table, $ds);
    }
}
```

Note that you do not need to do  `var $validate = array();` before the constructor. You can also place any other variables that you would like to translate in the constructor, like I do with my $visibilities variable. Then you'll no longer get that silly `trigger()` error message. And your app will work again. Hurray! Whoagies unite!
