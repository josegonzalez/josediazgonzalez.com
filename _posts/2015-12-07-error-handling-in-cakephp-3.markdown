---
  title:       "Error Handling in CakePHP 3"
  date:        2015-12-07 12:00
  description: "Silly hacks you can use in your cakephp applications"
  category:    cakephp
  tags:
    - cakeadvent-2015
    - cakephp
    - errors
    - exceptions
  comments:    true
  sharing:     true
  published:   true
  layout:      post
  series:      CakeAdvent-2015
---

In CakePHP, you can attach custom error and exception handlers. The default one displays a stack trace in debug mode, and a set of http errors when debug is off. That's nice and all, but sometimes you need to know when your users are encountering errors, and since you aren't psychic, we need to store those somewhere. Thankfully, there are quite a few services that allow us to track bugs:

- [Airbrake](https://airbrake.io/)
- [Bugsnag](https://bugsnag.com/)
- [Sentry](https://getsentry.com/welcome/)
- [Opbeat](https://opbeat.com/)
- etc.

One annoying thing about error/exception handling in CakePHP is needing to attach two handlers:

```php
// in your config/bootstrap.php
$isCli = php_sapi_name() === 'cli';
if ($isCli) {
    (new ConsoleErrorHandler(Configure::consume('Error')))->register();
} else {
    (new ErrorHandler(Configure::consume('Error')))->register();
}
```

- `ConsoleErrorHandler`: For cli-based exceptions
- `ErrorHandler`: For web-based exceptions

This is necessary as the exception handler needs to render the exception information differently; the web error handler might want to use json for responses, or show an html message with an interactive stacktrace.

You *also* have to have two methods in your handlers:

- `handleError`: For PHP Errors. PHP 7 does some [magic](https://secure.php.net/manual/en/language.errors.php7.php) to make these catchable, so perhaps this one will go away someday.
- `handleException`: For thrown Exception instances.

Rather than implement all error handling logic twice, we'll go the trait-based route.

## Traits

Traits are composable units of behavior. They are similar to CakePHP Behaviors, though built into the PHP Core. They come in handy for exception handling in CakePHP as it becomes easy to implement the core logic of capturing an exception and just using that in multiple classes.

Below is a trait for the `Bugsnag` service:


```php
<?php
namespace App\Error\Bugsnag;

use Bugsnag_Client;
use Cake\Core\Configure;
use Exception;

trait BugsnagTrait
{

    public function handleError($code, $description, $file = null, $line = null, $context = null)
    {
        $client = $this->client();
        if ($client) {
            $client->errorHandler($code, $description, $file, $line);
        }

        return parent::handleError($code, $description, $file, $line, $context);
    }

    public function handleException(Exception $exception)
    {
        $client = $this->client();
        if ($client) {
            $client->notifyException($exception);
        }

        return parent::handleException($exception);
    }

    protected function client()
    {
        $apiKey = Configure::read('Bugsnag.apiKey');
        if (!$apiKey && defined('BUGSNAG_API_KEY')) {
            $apiKey = BUGSNAG_API_KEY;
        }

        if (!$apiKey) {
            return null;
        }

        $client = null;
        if ($apiKey) {
            $client = new Bugsnag_Client($apiKey);
            $config = Configure::read('Bugsnag.config');
            foreach ($config as $key => $value) {
                if (method_exists($client, $key)) {
                    $client->$key($value);
                }
            }
        }

        return $client;
    }
}
?>
```

And here is what my `ErrorHandler` looks like:

```php
<?php
namespace App\Error\Bugsnag;

use App\Error\Bugsnag\BugsnagTrait;
use Cake\Error\ErrorHandler as CoreErrorHandler;

class ErrorHandler extends CoreErrorHandler
{
    use BugsnagTrait;
}
?>
```

Notice how the `ErrorHandler` class itself is devoid of any "real" logic? I've pushed all the heavy-lifting into the trait and then just ensured my `ErrorHandler` extends the CakePHP core `ErrorHandler`. Similarly, my `ConsoleErrorHandler` is quite empty as well:

```php
<?php
namespace App\Error\Bugsnag;

use App\Error\Bugsnag\BugsnagTrait;
use Cake\Console\ConsoleErrorHandler as CoreConsoleErrorHandler;

class ConsoleErrorHandler extends CoreConsoleErrorHandler
{
    use BugsnagTrait;
}
?>
```

## Homework time

While the logic I implemented is fairly easy to understand, it may also not give the full picture around the exception. For instance, many error collection services provide the ability to add extra metadata to an error, such as the user that was signed in, or client information such as operating system version. `ExceptionRenderer` instances can have access to this information using their `_getController` methods, and it wouldn't be too much work to copy that logic into your `ErrorHandler` to add extra metadata to the request.

I recommend customizing the error handler to fit your needs - adding metadata, or perhaps using a different service - and seeing what helps you find, replicate, and fix bugs your automated testing didn't catch.
