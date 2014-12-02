---
  title:       "Building Service Classes"
  date:        2013-12-06 12:41
  description: "Building complex pages that seem to span hundreds of lines of Controller/Model code? Write Service classes for greater good!"
  category:    CakePHP
  tags:
    - CakeAdvent-2013
    - cakephp
    - refactoring
    - service-oriented-architecture
  comments:    true
  sharing:     true
  published:   true
  layout:      post
  series:      CakeAdvent-2013
---

> The following can apply to any framework or application. I actually took the code sample from my job's Symfony application.

One of the things I keep finding in my applications are, regardless of my desire to move as much as possible into the model, the controller layer still ends up being hundreds of lines long. I retrieve data, check it against the request, retrieve more data conditionally, send tracking requests to backend services, start ab tests etc. And we haven't even talked about responding to multiple request content types.

For any reasonably complex application, you will eventually get to the point where you have controller actions and model methods that are hundreds of lines long and deal with the generation of your main, revenue generating page. This is both hard to grok from a developer standpoint and more costly to test/replace/extend from a business standpoint.

Let's take a simple example. We'll only show controller code to make the example brief:

> Code here is pseudo-code. Please don't expect these methods to exist ;)

```php
<?php
class EventsController extends AppController {
  public function view() {
    $this->Abtest->convert(array(
      'test' => 'kpi',
      'test-two'
    ));

    $embeddedPage = false;
    if ($this->_isDisplayedInIframe()) {
      $this->_noIndex();
      $embeddedPage = true;
      $event = $this->Event->findEvent($this->request->params);
    } else {
      $event = EventApi::retrieve($this->request->params('event_id'));
    }

    if (!$event) {
      throw new NotFoundException;
    }

    // A 40 line function
    if ($this->_incorrectRouteForEvent($event)) {
      return $this->redirect($event->getRoute());
    }

    if ($this->_hasTrackingParams()) {
      $this->_trackPage($event);
      return $this->redirect301($event->getRoute());
    }

    $apiEvent = EventApi::retrieve($event->get('id'));
    $recommendations = $this->getRecommendations();
    // etc.
  }
}
?>
```

Already, for a nontrivial event, for things that most can agree should be in the controller layer, we have 60 lines of code. We didn't:

- Retrieve all data necessary for the page
- Set custom SEO metadata
- Start new ab tests
- Add custom tracking info
- Handle multiple response types

So as you can imagine, the logic could get very hairy.

## Service classes

A service class is a wrapper around logic. It would contain everything necessary to handle the rendering of a page. Typically, CakePHP developers move as much as possible into the Model layer, but that isn't always possible, as you can't really handle page redirects for instance. Another thing is that - in my opinion - a Model class should only speak to a single data layer. It should not speak to multiple disparate apis. In our above example, we hit three different api endpoints, only one of which is a database in the traditional sense.

Your best bet would be to create a service class. This can be a component or just a new library. Lets use a new library. This allows us to ignore loading of a new class for every request in a given controller.

```php
<?php
class EventPage {
  public function __construct(Controller $controller) {
    $this->_controller = $controller;
    $this->_request = $controller->request;
  }

  public function run() {
    $this->trackAbTests();

    // Non-boolean responses == redirect
    // You could also throw an exception that performs a redirect in your ExceptionHandler
    $response = $this->retrieveEvent();
    if ($response !== true) {
      return $this->redirect($response);
    }

    $this->checkPageEmbedding();
    $response = $this->ensureProperRoute();
    if ($response !== true) {
      return $this->redirect($response);
    }

    // Complex logic in each of these methods
    $this->trackPage();
    $this->retrieveData();
    $this->setupResponse();
  }
}
?>
```

Our 60+ line controller action now becomes:

```php
<?php
class EventsController extends AppController {
  public function view() {
    $eventPage = new EventPage($this);
    return $eventPage->run();
  }
}
?>
```

This methodology is very powerful in that it allows you to continue developing in a manner you are otherwise familiar with, while still making it simple to understand how a page is being constructed.

**Fat Models, Skinny Controllers** is now **Fat Models, Intelligent Services Classes, Skinny Controllers** :)

