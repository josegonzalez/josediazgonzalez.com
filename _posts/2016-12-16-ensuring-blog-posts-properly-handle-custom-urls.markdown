---
  title:       "Ensuring Posts properly handle custom urls"
  date:        2016-12-16 04:16
  description: "Part 16 of a series of posts that will help you build out a personal CMS"
  category:    cakephp
  tags:
    - application-rules
    - validation
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

## Validating custom urls

Each one of our posts can be assigned a url. Previously, this could be any non-empty string. Let's put in some ground rules:

- It should be unique in our database.
- The url will be automatically generated from the `title` field if not otherwise specified
- It should start with a forward slash.
- It should not end with a forward slash.
- All special characters should be replaced with dashes.
- It must be lowercase.
- It cannot be within a specific set of whitelisted urls.
- It cannot be prefixed with a specific set of strings.

Lets start with the first item:

### Application Rules

Application Rules differ from Validation rules. Validation rules should be stateless - that is, they are not affected by datastore lookups or similar. You can use them to check types or values. Application Rules *are* stateful, and are typically used for stuff like "this field must be unique" or "the state change of this field is invalid". We're going to use the former and modify our `PostsTable::buildRules()` method to be the following:

```php
/**
 * Returns a rules checker object that will be used for validating
 * application integrity.
 *
 * @param \Cake\ORM\RulesChecker $rules The rules object to be modified.
 * @return \Cake\ORM\RulesChecker
 */
public function buildRules(RulesChecker $rules)
{
    $rules->add($rules->existsIn(['user_id'], 'Users'));
    $rules->add($rules->isUnique(['url']));

    return $rules;
}
```

I'll commit here:

```shell
git add src/Model/Table/PostsTable.php
git commit -m "Force the url field to be unique"
```

### Auto-generating urls

First, we'll need to allow fields to be "empty" in the form. Remove the following from `AbstractPostType::_buildValidator()`:

```php
$validator->notEmpty('url', 'Please fill this field');
```

Next, lets generate the url when empty! I've added the following class to our use statements at the top of my `AbstractPostType` class:

```php
use Cake\Utility\Hash;
```

Right after we call `AbstractPostType::transformData()` inside of `AbstractPostType::_execute()`, I call the following:

```php
$data['url'] = $this->ensureUrl($data);
```

And here is the body of `AbstractPostType::ensureUrl()`.

```php
protected function ensureUrl(array $data)
{
    $url = trim(Hash::get($data, 'url', ''), '/');
    if (strlen($url) !== 0) {
        return $url;
    }

    return Hash::get($data, 'title', '');
}
```

We leave the url alone if the user has specified one, and otherwise return the contents of the `title` field.

Finally, we can strip values from the url by adding a `_setUrl()` method to our Post entity. This ensures that it is properly massaged whenever that value is set, without requiring extra work at other layers. I've created a `UrlSettingTrait` in `src/Model/Entity/Traits/UrlSettingTrait.php` that contains the following:

```php
<?php
namespace App\Model\Entity\Traits;

use Cake\Utility\Text;

trait UrlSettingTrait
{
    /**
     * Trims slashes and prepends the url with a slash
     * If the input is invalid - such as an empty string - the url will become null.
     *
     * @param string $url The url that is to be set
     * @return string
     */
    public function _setUrl($url)
    {
        if (strlen($url) === 0) {
            return '';
        }

        $url = Text::slug($url, [
            'lowercase' => true,
            'replacement' => '-',
        ]);
        $url = '/' . trim($url, '/');
        if ($url === '/') {
            $url = null;
        }

        return $url;
    }
}
```

You'll need to `use` this class within your `Post` entity as well.

```php
use \App\Model\Entity\Traits\UrlSettingTrait;
```

I'll save our progress now:


```shell
git add src/Model/Entity/Post.php src/Model/Entity/Traits/UrlSettingTrait.php src/PostType/AbstractPostType.php
git commit -m "Automatically generate urls from the title field"
```

### Validating the `url` field

We'll want to ensure we don't set invalid urls. For instance, shadowing an existing route would potentially break stuff like the admin or similar. In our next post, I'll cover how to use admin routing for our dashboard, as well as custom routes for all other pages, but just assuming that the following urls are to be whitelisted:

- `/`
- `/about`
- `/home`
- `/contact`
- `/login`
- `/logout`
- `/forgot-password`

I'll add the following to my `PostsTable::validationDefault()` method:

```php
$validator->add('url', 'notInList', [
    'rule' => function ($value, $context) {
        $list = ['/', '/about', '/home', '/contact', '/login', '/logout', '/forgot-password'];
        $list = array_map('strval', $list);
        return !in_array((string)$value, $list, true);
    },
    'message' => 'Reserved urls cannot be specified',
]);
```

> We may want to expand this list later, but for now this seems adequate.

We have to use a custom rule here because the built-in CakePHP rules cannot be negated, otherwise we would use `inList.

Urls must also not be prefixed with any of the following:

- `/admin`
- `/reset-password`
- `/verify`

We'll use another custom validation rule for this.

```php
$validator->add('url', 'withoutPrefix', [
    'rule' => function ($value, $context) {
        if (preg_match("/^\/(admin|reset-password|verify)/", $value)) {
            return false;
        }
        if (preg_match("/^(admin|reset-password|verify)/", $value)) {
            return false;
        }
        return true;
    },
    'message' => 'Urls cannot start with "/admin", "/reset-password", or "/verify"',
]);
```

I've used two regex matches because urls can be set with a starting forward slash or not, and the `Post` entity setter will ensure they start with one. Allowing both makes it easier for users to reason about what the url will look like, as we'll handle it correctly on our end.

> Validation rules can contain inline functions, which are useful in a pinch but also more difficult to test

Remember to save your work.

```shell
git add src/Model/Table/PostsTable.php
git commit -m "Properly validate a submitted url"
```

### Persisting error messages

One thing you might notice when saving a post is that the validation errors from the `PostsTable` are not shown. This is because we are overwriting the template's entity in our `PostsListener::_setPostType()` method. I've added the following right before I update the template entity in that method:

```php
$postType->mergeErrors($event->subject->entity->errors());
```

And here is the code for `AbstractPostType::mergeErrors()`. We want to ensure any existing errors from other places are properly persisted, so we need to merge our post errors *onto* the post type:

```php
public function mergeErrors(array $errors)
{
    foreach ($errors as $field => $err) {
        if (!isset($this->_errors[$field])) {
            $this->_errors[$field] = $err;
            continue;
        }
        foreach ($err as $name => $message) {
            $this->_errors[$field][$name] = $message;
        }
    }
}
```

> This code is not unit tested, and error handling is a place where you may want to dive into unit testing to ensure you get it right. We may end up revisiting this implementation at a later date.

If you try out the form now, you'll see that we now have all the errors from our Post instance validation. I'll save my work for now:

```shell
git add src/Listener/PostsListener.php src/PostType/AbstractPostType.php
git commit -m "Persist validation errors when saving forms"
```

---

> For those that may just want to ensure their codebase matches what has been done so far, the codebase is available on GitHub and tagged as [0.0.16](https://github.com/josegonzalez/cakeadvent-2016/tree/0.0.16).

We have now placed some mitigations in place for ensuring our users do not set invalid urls. We can now look into the routing layer portion of this, which will make the user-facing portion of our site much more usable.

Be sure to follow along via twitter on [@savant](https://twitter.com/savant). If you'd like to subscribe to this blog, you may follow the [rss feed here](/atom.xml). Also, all posts in the series will be conveniently linked on the sidebar of every post in the 2016 CakeAdvent Calendar. Come back tomorrow for more delicious content.
