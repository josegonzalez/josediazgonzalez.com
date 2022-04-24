---
  title:       "What exactly belongs in an entity?"
  date:        2015-12-04 12:00
  description: "Silly hacks you can use in your cakephp applications"
  category:    cakephp
  tags:
    - cakeadvent-2015
    - cakephp
    - table
    - entities
  comments:    true
  sharing:     true
  published:   true
  layout:      post
  series:      CakeAdvent-2015
---

> Sorry for the lateness, I was at a basketball game. The Nets lost against the Knicks, if anyone was wondering.

I've been in a few arguments about what an "entity" is. CakePHP 3 introduced them as a new way of representing a distinct set of data from a collection of "things". Typically, that means a row in a table.

```php
$post = new Post;
```

For a very long time, this was not how CakePHP abstracted information. You had an array, you modified an array, you saved an array, you deleted an array. GRONK WAS HAPPY!

![My cowork Rick O'Hanlon](http://www.catster.com/wp-content/uploads/2015/06/RobGronkowski4.png)

Honestly though, the array stuff was quite annoying, and most (all?) CakePHP are happy we replaced them in CakePHP 3. The ORM changes that came along with it were... weird, but make sense once you think about them. But what exactly do I gain with an entity?

## Custom Entity Data

An entity is a bag of data. It is a data bag. You put some data in it, and you can get that data out.

*breathe* _plays anna nalick_

When you first use an entity, you should treat it as a dumb object. Previously, we would say "Fat Models, Skinny Controllers". I think the same way about entities. Entities are fairly stupid. They know about themselves and not much else. That is to say, entities don't and shouldn't know how to save themselves, what it means to be a valid entity (save the mid-life crisis for a table), or really much of anything.

*Entities are for holding data and virtually constructed data.* If you have a `Post` entity with information about a post, it may be able to constuct it's published date, the number of views it has, or whether it is active or not, but it should *not* know whether or not it is the latest version of a post, or whether it's internal state is valid. These things should be left to tables and validators.

> In the case of validators, they may change the state of an entity to add errors etc., but I don't think of this as the state. The ORM will refuse to save an invalid entity, so really all you have is a bad bag of data that you need to clean up. The validation errors tell you how to do that.

## What is in an Entity?

![No really, what the hell does an entity stand for?](https://1.bp.blogspot.com/-6d78XHD9qIQ/TsE7oLbG_nI/AAAAAAAAABE/XgB3ci9zv4o/s1600/Baby+names.jpg)

We've always had "App" classes in PHP. What is an `App` class? It's literally a parent class that we use to contain some amount of default logic. You can create as many of these as you'd like. The `App` prefix is just a standard, I like to call mine `Lolipop`  classes when no one is looking.

Here is my default `LolipopEntity` class (hey, we have object oriented programming up in the hizouze!). You can place what you'd like in yours, I recommend seeing what is common and just doing that once:

```php
<?php
namespace App\Model\Entity;

use App\Model\Entity\Traits\JsonApi;
use Cake\ORM\Entity;

class LolipopEntity extends Entity
{
    use JsonApi;
}
?>
```

Okay, that is cheating. You can see I include the `JsonApi` trait, and here it is:

```php
<?php
namespace App\Model\Entity\Traits;

use Cake\Routing\Router;
use Cake\Utility\Inflector;

trait JsonApi
{
    public static function className()
    {
        $classname = get_called_class();
        if (preg_match('@\\\\([\w]+)$@', $classname, $matches)) {
            $classname = $matches[1];
        }

        return $classname;
    }

    public function _getType()
    {
        $classname = static::className();
        return Inflector::classify($classname);
    }

    public function _getRoute()
    {
        $classname = static::className();

        return [
            'controller' => Inflector::pluralize(Inflector::classify($classname)),
            'action' => 'view',
            '_method' => 'GET',
            'id' => $this->id,
        ];
    }
}
?>
```

The `JsonApi` trait is something I use for building out APIs. My `AppEntity` sometimes includes a `toArray` that pulls in these false methods, or I include them manually in subclasses. I also have other related methods that build upon the data an entity has to create information _about_ that entity.

Entities are bags of data, and while they are supposed to be stupid, in my view they should understand how to reference themselves. This is controversial amongst the core developers, but I take this stance because I like to keep my code DRY.

> DONT REPEAT YOURSELF. Repeat after me (because I won't!).

Let's say you have a database of events. Each event has a url, and you have custom routes for that url (to include seo information etc.). Each time you change the custom route, you may or may not have to change route information included to generate that route.

```php
$this->Html->link('Awesome Event with Milkshakes', [
  'controller' => 'Events',
  'action' => 'view',
  'id' => $entity->id,
  'slug' => $entity->slug,
]);
```

At some point, writing the above out gets annoying. And while the reference to an object happens in the presentation layer and is probably easily done in a helper, isn't it nice to do something like:

```php
$this->Html->link('Awesome Event with Milkshakes', $entity->getRoute());
```

The alternative is a helper to which you pass an entity, or always writing out the array.

## A Best Practice, or at least a "Practice"

While I may disagree with the core developers on what goes where, we can all agree that at the end of the day, you should strive to write the least amount of code that works which won't give you a headache at some other time. In my case, it is adding some presentational data to the `entity` object. Maybe in your case, that means never using plugins or shirking away from namespaces.

Remember, there are many ways to skin a cat (please don't hurt my cat). So long as you aren't increasing anyone's cognitive load, choose the method that involves the least code.

> Always code as if the person who ends up maintaining your code is a violent psychopath who knows where you live. - [Code For The Maintainer](http://c2.com/cgi/wiki?CodeForTheMaintainer)
