---
  title:       "Parsing markdown comments"
  date:        2014-12-07 13:45
  description: "Part 6 of 7 in a series of posts designed to teach you how to use CakePHP 3 effectively"
  category:    CakePHP
  tags:
    - cakeadvent-2014
    - cakephp
    - composer
    - helpers
  comments:    true
  sharing:     true
  published:   true
  layout:      post
  series:      CakeAdvent-2014
---

In CakePHP 3, some things change significantly, and others stay pretty much the same. CakePHP 3 provides a new `AppView` class in `app/src/View/AppView.php`. You can do any of the following here:

- Load helpers for every template
- Override `View` methods
- Add custom methods that may not necessarily require a new helper

In our case, we'll be making a new `MarkdownHelper` available everywhere. As such, our `AppView` will look similar to the following:

```php
<?php
namespace App\View;

use Cake\View\View;

class AppView extends View {
    public function initialize() {
        $this->loadHelper('Markdown');
    }
}
?>
```

### Creating a new helper

In our helper, we're going to depend upon the `colinodell/commonmark-php` package to render markdown that follows the [CommonMark](http://commonmark.org/) specification. First, you'll want to install that package using `composer`:

```shell
# ssh onto the vm
vagrant ssh

cd /vagrant/app
composer require colinodell/commonmark-php:0.3.0
```

> The `colinodell/commonmark-php` package will be named `league/markdown` shortly, but for now, these instructions should work fine.

Now we can create a very simple helper class. Helper classes allow us to format output for templates in a more user friendly format. We could, for instance, use a helper to generate the correct gravatar url for a given email address. Helpers allow you to consolidate your template logic into classes that can be easily tested and reused not just in a single application, but across multiple applications that need the same functionality.

You should first create the file containing your new helper:

```shell
cd /vagrant/app
touch app/src/View/Helper/MarkdownHelper.php
```

The contents of our helper will then be the following:

```php
<?php
namespace App\View\Helper;

use Cake\View\Helper;
use Cake\View\View;
use ColinODell\CommonMark\CommonMarkConverter;

class MarkdownHelper extends Helper {
    public function __construct(View $view, $config = []) {
        parent::__construct($view, $config);
        $this->Converter = new CommonMarkConverter;
    }

    public function out($input) {
      return $this->Converter->convertToHtml($input);
    }
}
?>
```

To use our helper, anytime we output `Comment` or `Issue` contents, we would wrap them in a call to our helper:

```php
// For issues
$this->Markdown->out($issue->text);

// For comments
$this->Markdown->out($comment->comment);
```

Helpers can be a pretty simple way of consolidating logic in your template files. While in this case there wasn't much work to be done, you might want to consider using helpers for outputting stuff like navigation bars, custom form elements, and automatically parsing urls into embeddable images and videos.

### Homework Time!

Since it's still sunday, we're going to skip homework. I'm going to personally listen to the guy playing jazz two apartment buildings down and go to Fifthsgiving in an hour. Let me know in the comments if you have any feedback, and see you all tomorrow!
