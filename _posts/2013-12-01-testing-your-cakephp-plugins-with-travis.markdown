---
  title:       "Testing your CakePHP Plugins with Travis"
  date:        2013-12-01 16:22
  description: "Quickly setup automated testing for your cakephp plugin code using Travis-Ci"
  category:    CakePHP
  tags:
    - CakeAdvent-2013
    - cakephp
    - travis
  comments:    true
  sharing:     true
  published:   true
  layout:      post
  series:      CakeAdvent-2013
---

As you work on a plugin, you'll find that ensuring the external api stays stable is difficult. The obvious solution is to write [unit tests](http://book.cakephp.org/2.0/en/development/testing.html), and run them as you develop.

It's very easy to write unit tests:


```php
<?php
App::uses('Article', 'Model');

class ArticleTest extends CakeTestCase {
    public $fixtures = array('app.article');

    public function setUp() {
        parent::setUp();
        $this->Article = ClassRegistry::init('Article');
    }

    public function testPublished() {
        $result = $this->Article->published(array('id', 'title'));
        $expected = array(
            array('Article' => array('id' => 1, 'title' => 'First Article')),
            array('Article' => array('id' => 2, 'title' => 'Second Article')),
            array('Article' => array('id' => 3, 'title' => 'Third Article'))
        );

        $this->assertEquals($expected, $result);
    }
}
?>
```

But it is quite another thing to ensure that *every* version of the code has had unit tests run against them.

That said, the easy solution is **continuous integration**. Continuous Integration is the process by which your code - hopefully in a branch! - is merged into the mainline branch - usually master - and having automated unit tests run. Lots of applications and services exist for this - Hudson, Jenkins, Buildbot - but today I'll show you a free service called [Travis](http://travis-ci.com/).

Travis allows you to use a `.travis.yml` to run unit tests on their infrastructure, and is free to use for open source projects. The following is a very simple `.travis.yml`:

```yaml
language: python
python:
  - "2.7"
# command to run tests
script: nosetests
```

The above runs automated tests for a python application. Which is nice, but we want CakePHP plugins.

Friends Of Cake has built a *delicious* integration with Travis which is available on [github](https://github.com/friendsofcake/travis). Usage is actually pretty simple:

```bash
# example for Crud plugin
# assumes plugin is in path/to/app/Plugin/Crud
cd path/to/app

# Clone the repo down
git clone git@github.com:FriendsOfCake/travis.git vendor/travis

# Export some environment variables for running the setup script
export COPYRIGHT_YEAR=2011
export GITHUB_USERNAME="friendsofcake"
export PLUGIN_PATH="Plugin/YourPlugin"
export PLUGIN_NAME="YourPlugin"
export REPO_NAME="your-plugin"
export YOUR_NAME="Christian Winthers"

# Run the setup
./vendor/travis/setup.sh

# Remove this repository when you are done
rm -rf vendor/travis
```

From the readme:

> The script will:
>
> - Retrieve configuration specified
> - Template out files for submission to the FriendsOfCake organization, http://travis-ci.org, and http://packagist.org
> - Template out other missing files, such as a README.markdown and an AllPluginNameTest.php
> - Write a notice for signing up to http://coveralls.io

Once done, simply register your [github repository on TravisCi](http://about.travis-ci.org/docs/user/getting-started/) and you will be set for continuous integration.

Give your plugins the gift of automated testing, and give yourself the day off from worrying about potential api breakages :)
