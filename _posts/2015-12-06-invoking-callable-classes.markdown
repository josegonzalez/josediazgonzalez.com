---
  title:       "Invoking Callable Classes"
  date:        2015-12-06 12:00
  description: "Silly hacks you can use in your cakephp applications"
  category:    cakephp
  tags:
    - cakeadvent-2015
    - cakephp
    - callables
    - events
  comments:    true
  sharing:     true
  published:   true
  layout:      post
  series:      CakeAdvent-2015
---

CakePHP has offered the use of callables for invoking related logic since 2.x with the event system. They are great for expressing self-contained pieces of logic, but not so much for avoiding spaghetti code.

```php
$this->eventManager()->on('event', function (\Cake\Event\Event $event) {
    // complex logic here
});
```

This only gets worse in CakePHP 3, where you now have to deal with formatters, custom rules, and other such niceties that are easier to handle via callbacks.

One other drawback is that your code is no longer testable in isolation. You need to execute the enclosing block in order to even try to trigger the anonymous function. Thankfully, callables can be classes!

```php
use \Cake\Event\Event;
class SomeCallable
{
    public function __invoke(Event $event)
    {
        // complex logic here
    }
}
```

Since PHP 5.4, we also have the `Callable` typehint, which you can use in your own functions when interacting with either invokable classes or anonymous functions.

Some notes:

- I try and place my callables in a logical namespace. Formatters go in `\App\Table\Formatters`. Event handlers go in `\App\Event\Handlers`. You get the idea.
- You can pass in the callable by sending in an instance of that class. `__invoke` will be run automatically.
- I like adding a `run` or `perform` method that calls the `__invoke` method. This makes it easy for me to reuse the class in non-callable situations.
- You can test these just like any other class, or refactor your long anonymous function into a set of helper methods to simplify readability.
