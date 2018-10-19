---
  title:       The Daily Dev Log - 1
  category:    dev-log
  tags:
    - daily-dev-log
    - history.js
    - javascript
    - jquery
  description: I spent around 7 hours putzing with History.js in cake_admin. While History.js should auto-ajax any web application, it doesn't quite play nice with CakePHP.
  comments:    true
  sharing:     true
  published:   true
  layout:      post
---

I spent around 7 hours putzing with [History.js](https://github.com/balupton/history.js) in [cake_admin](https://github.com/josegonzalez/cake_admin). History.js is a Javascript library-agnostic wrapper around the HTML5 History Api, which gives a way for ajax requests to manipulate the state of the browser.

For example, say I enable History.js for all my pagination links, but nothing more. I click a link and the following javascript is performed:

```javascript
(function(window, undefined) {
    // Prepare
    var History = window.History; // Note: We are using a capital H instead of a lower h
    if ( !History.enabled ) {
        // History.js is disabled for this browser.
         // This is because we can optionally choose to support HTML4 browsers or not.
        return false;
    }

    function change_page($name, $link, $complete) {
        var opts = {
            dataType: 'html',
            evalScripts: true,
            success: function (data) {
                $('#content').fadeOut(400, function() {
                    History.pushState(null, null, $link);
                    $('#content').html(data);
                    $('#content').fadeIn();
                });
            },
            url: $link
        };

        if ($complete) {
            opts['complete'] = $complete;
        }
        $.ajax(opts);
    }
    $('.paging a').live('click', function (e) {
        e.preventDefault();
        change_page($(this).html(), $(this).attr('href'));
    });
})(window);
```

What that does is prevents the link from firing it's normal event and _changes_ the page. By changing, I mean it fires an ajax request to the server for the contents of `#content` - for CakePHP that's whatever would normally be in `$content_for_layout` - pushes this state into the History in a cross-browser compatible way, and then inserts the requested content into `#content`. Neat, huh?

The problem occurs when you request a non-ajax link. This does a full-page reload of the new page (cool), but selecting the `back-button` or pushing the `backspace` will cause the browser to load only the contents served via that previous ajax request (not so cool). Since it was only the inner contents, it was both unexpected and unstyled. Going back was broken in general, regardless of whether the current page was an ajax request or not, so I modified the above to read as follows:

```javascript
(function(window, undefined) {
    // Prepare
    var History = window.History; // Note: We are using a capital H instead of a lower h
    if ( !History.enabled ) {
        // History.js is disabled for this browser.
         // This is because we can optionally choose to support HTML4 browsers or not.
        return false;
    }

    var history_hack = false;

    $(window).bind("statechange", function() {
        if (history_hack === true) {
            history_hack = false;
            return;
        }

        var State = History.getState();
        History.log(State.data, State.title, State.url);
        $.ajax({
            dataType: 'html',
            evalScripts: true,
            success: function(data) {
                $('#content').fadeOut(400, function() {
                    $('#content').html(data);
                    $('#content').fadeIn();
                });
            },
            url: State.url
        });
        history_hack = false;
    });

    function change_page($name, $link, $complete) {
        var opts = {
            dataType: 'html',
            evalScripts: true,
            success: function (data) {
                history_hack = true;
                $('#content').fadeOut(400, function() {
                    History.pushState(null, null, $link);
                    $('#content').html(data);
                    $('#content').fadeIn();
                });
            },
            url: $link
        };

        if ($complete) {
            opts['complete'] = $complete;
        }
        $.ajax(opts);
    }
    $('.paging a').live('click', function (e) {
        e.preventDefault();
        change_page($(this).html(), $(this).attr('href'));
    });
})(window);
```

So now I have this nice `history_hack` that fixes the `back-button` for ajax requests, but not so much for non-ajax requests. At this point, I had to look at how the History.js example works.

History.js' [example](https://gist.github.com/854622) actually requests the full page and parses out the parts we aren't going to put into the page. This is good because sometimes the sidebar links don't change, or maybe we want a specific section to be ajax'ed in.

CakePHP, however, is a bit more devious. You normally use the `RequestHandlerComponent` to do Ajax in conjunction with the `JsHelper` (my JS is actually based on the real duplicated code the `JsHelper` creates). `RequestHandler::startup()` sets the layout to be false, meaning I can't take the path of `History.js`. Bummer. I was going to try and be devious by setting a different `dataType` in the `jQuery.ajax()` call and then putzing around in my `AppController::beforeFilter()` or `AppController::beforeRender()`, but there don't appear to be a good dataType to use that `jQuery.ajax()` won't choke on. This would also break my existing Js (not a big deal), and I would have to rewrite/extend the `RequestHandler` (big deal), but I can live with that.
