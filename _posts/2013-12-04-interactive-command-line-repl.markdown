---
  title:       "Interactive command-line REPL for CakePHP"
  date:        2013-12-04 00:53
  description: "Lets explore different ways in which we could implement an interactive command-line for the purposes of quickly testing code"
  category:    CakePHP
  tags:
    - cakeadvent-2013
    - cakephp
    - cli
    - repl
  comments:    true
  sharing:     true
  published:   true
  layout:      post
  series:      CakeAdvent-2013
---

> REPL: A read–eval–print loop. It allows developers to test, write and run code interactively from the command-line.

One constant annoyance I have with PHP is it's lack of a decent, built-in REPL. PHP does have a REPL, but it:

- doesn't automatically print the output of each command
- auto-exits on fatal errors, causing you to lose work
- doesn't have pretty output by default :(

All I want to do is the following:

```shell
Console/shell
cakephp> App::uses('ClassRegistry', 'Utility');
cakephp> App::uses('Post', 'Model');
cakephp> $posts = ClassRegistry::init('Post');
cakephp> $posts->find('first');
 → array(
  0 => array(
    'Post' => array(
      'id' => '1',
      'title' => 'The title',
      'body' => 'This is the post body.',
      'created' => '2013-12-03 04:47:58',
      'modified' => NULL
    )
  )
)
```

Luckily, there are a few options for CakePHP:

# Console Shell

There is a Console Shell in CakePHP. It allows you do the following:

![http://cl.ly/image/1H0X3g2k3I27](http://f.cl.ly/items/1b0M3V033f043d2K110o/Screen%20Shot%202013-12-04%20at%203.38.17%20AM.png)

Thats cool. A few issues though:

- Very limited. Basically only useful for Model finds and routes. Doesn't do much else. For example, `echo "hi";` returns `Invalid command`
- Not native PHP output. Try copy-pasting the output into an editor. Then spend the rest of your life reformating it.
- Deprecated as of 2.4, and will be removed in 3.x

# Boris

Boris is a relative newcomer to PHP repl land. It's a pure-php REPL with some interesting code behind the implementation. We'll first need to install it:

```shell
cd path/to/app/Vendor
git clone git@github.com:d11wtq/boris.git
```

Next we'll need something to bootstrap the CakePHP codebase. We will create a file called `app/Console/boris`. You'll need to set proper permissions on it:

```shell
chmod +x app/Console/boris
```

Next, we need to bootstrap some constants. The CakePHP `ShellDispatcher` class does this, though we'll need to make a few exceptions to it. Lets ensure we can include it (the code snippets here will all be in the same file!):

```php
#!/usr/bin/php -q
<?php
$ds = DIRECTORY_SEPARATOR;
$dispatcher = 'Cake' . $ds . 'Console' . $ds . 'ShellDispatcher.php';
if (function_exists('ini_set')) {
  $root = dirname(dirname(dirname(__FILE__)));

  // the following line differs from its sibling
  // /lib/Cake/Console/Templates/skel/Console/cake.php
  ini_set('include_path', $root . $ds . 'lib' . PATH_SEPARATOR . ini_get('include_path'));
}

if (!include $dispatcher) {
  trigger_error('Could not locate CakePHP core files.', E_USER_ERROR);
}
unset($paths, $path, $dispatcher, $root, $ds);
?>
```

Next, we'll create a wrapper `BorisShellDispatcher` which will contain our customizations:

```php
<?php
class BorisShellDispatcher extends ShellDispatcher {
  public function __construct($args = array(), $bootstrap = true) {
    set_time_limit(0);
    $this->parseParams($args);

    if ($bootstrap) {
      $this->_initConstants();
      $this->_bootstrap();
    }
  }

  public static function run($argv) {
    $dispatcher = new BorisShellDispatcher($argv);
  }
}
?>
```

The customizations are enforced because we don't want to run a CakePHP shell, we simply want to borrow the initialization code for constants etc.

Finally, lets run our custom dispatcher and start the boris runner:

```php
<?php
BorisShellDispatcher::run($argv);

if (!include (ROOT . DS . 'app' . DS . 'vendor' . DS . 'boris' . DS . 'lib' . DS . 'autoload.php')) {
  trigger_error("Unable to load boris autoload.", E_USER_ERROR);
  exit(1);
}

$boris = new \Boris\Boris('cakephp> ');

$config = new \Boris\Config();
$config->apply($boris);

$options = new \Boris\CLIOptionsHandler();
$options->handle($boris);

$boris->start();
?>
```

Lets run it!

![http://cl.ly/image/1R2a0Y2b0710](http://cl.ly/image/1R2a0Y2b0710/Screen%20Shot%202013-12-04%20at%203.58.28%20AM.png)

Pretty slick, but a few (minor) quirks:

- Doesn't seem like you can call `App::uses()` before `$boris->start()` and have the loaded files persist.
- Output is sometimes verbose. If you just do `$posts = ClassRegistry::init('Post')`, it outputs the `$posts` object
- Doesn't work on Windows. Using Vagrant would solve this!

## Interactive shell for CakePHP

This is something from [@nodesagency](https://github.com/nodesagency). It is a CakePHP shell, similar to the `Console` shell, but in plugin format. We'll need to install it first:

```shell
git clone git://github.com/nodesagency/cake-interactive-shell.git app/Plugin/Interactive
```

We'll also need to enable it:

```php
<?php
// in app/Config/bootstrap.php
CakePlugin::load('Interactive');
?>
```

And now install it:

```shell
Console/cake Interactive.Install
```

Lets try our commands:

![http://cl.ly/image/0F21373g0v2d](http://cl.ly/image/0F21373g0v2d/Screen%20Shot%202013-12-04%20at%204.45.51%20AM.png)

Well that didn't work. Guess there are a few bugs, or we need to make our own database connection?

One other (small) issue. This shell appears to require `phpsh` from Facebook. That project has been unmaintained for 3 years, and requires `readline`, `ncurses`, and `emacs` to build properly. I know because I had to go down a thirty-minute rabbit hole to figure that out. Annoying, but if you ever get it working, the above information is important if you ever want to actually install `phpsh`.

The plugin didn't load any required files without `phpsh`, so it appears to be unmaintained. Boo.

## The straight skinny

I think your current best bet is to use `Boris`. It's quite easy to install, and other than not having an official CakePHP integration, is the best of the group atm.

Going forward, I expect to see CakePHP get a more officially-sanctioned integration with REPLs such as Boris - and I expect there will be more like them - so we'll see where 3.0 brings us!
