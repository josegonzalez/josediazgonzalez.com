---
  title:       Why to Actually Choose CakePHP
  date:        2012-09-07 00:00
  description: Why I think CakePHP is a great framework option
  category:    cakephp
  tags:
    - cakephp
  comments:    true
  sharing:     true
  published:   true
  layout:      post
---

{% blockquote %}
For those looking for the original, Symfony post, please read <a href="http://fabien.potencier.org/article/65/why-symfony">Fabian's excellent post here</a>. I still would choose CakePHP, but Symfony might jive with you :)
{% endblockquote %}


When I started working with CakePHP - I knew very little about practical development (my coworkers might say I still know very little :P). I went about choosing my framework on the following criteria:

- How fast I could go through the tutorial
- Quality of the documentation
- Code samples and whether I needed to configure a lot
- Blog posts regarding it's usage in odd ways
- How easy it was for me to find open source code
- If it even ran on my computer

This was back in the days before:

- Github
- TravisCI
- Twitter (largely!)
- Coderwall/Forrst/Dribble/[other derpy site here]

So it was important for me to make as an "informed" decision as possible.

- Symfony's tutorial was 30 days long. I didn't have that much time
- CodeIgniter's docs didn't make much sense to me, and their usage of a wiki put me off
- Kohana's site looked funny.
- Zend required setting up 35234524 classes in order to have "Hello World" print to the screen.

etc.

## Why CakePHP?

CakePHP failed - and still largely does, although now it's my fault - on code discoverability. It's strength, at least for me, was largely predicated on the massive amount of code on the Bakery, CakeForge, blog posts etc. It helped that the tutorial was 5 minutes long, and while that may be a poor metric to some, for the unitiated, that is a great stress reliever.

So at least for the first few months, I was happy to use CakePHP.

### Why not Rails?

Rails did not run on my mac. I don't know why. Even now, dependency management in Ruby doesn't always work for me. But Rails is a fine decision otherwise.

## Why STILL CakePHP?

Regardless of my status as a core developer - I actually just troll the private #irc room ;) - I believe CakePHP is one of the best PHP options today:

- **Passionate Core Developers**: While we do not have a company behind us - CakeDC doesn't count, as they just do consulting and most of the Core does not work there - all the volunteers are quite brilliant developers who are dedicated to CakePHP. Lots of interesting backgrounds, all with the common interest of making a great framework.
- **Release iteration**: We have, in the past, created more monolithic releases, but recently have moved towards much smaller ones. In just a year, we're already at a `2.2.2` release, with many new features that have followed developer trends more closely than before. As well, we're chugging full-steam at a 3.x release, which should relieve one of the last great *issues* with CakePHP - it's *ORM*.
- **The Model Layer**: The CakePHP model layer IS based on Arrays - I personally believe arrays have been and always will be king in PHP - but it is easy to use a [plugin for an object-oriented approach to CakePHP](https://github.com/kanshin/CakeEntity/tree/2.0) (I use it on my own projects). And we're making that the priority for 3.0. That said, it's both quite possible to use Objects now, and is not a hassle to integrate with [other](https://github.com/dkullmann/CakePHP-Elastic-Search-DataSource) [datasources](https://github.com/lorenzo/MongoCake). Please stop using this as an invalid reason as to why CakePHP sucks.
- **CakePHP loves the Open Source Community**: We have also embraced other framework projects - moved to PHPUnit for 2.0, pushed for a community-wide [Packagist installer](https://github.com/composer/composer/issues/820) - but realize that we should have opinions about things. I like knowing that all the CakePHP projects I encounter will invariably use the same AuthComponent, same core libraries, same Model layer, etc. Makes my freelance work easier.
- **CakePHP is about developer happiness**: CakePHP allows me to write less code to achieve the same affect as other developers. That means I have more time to plan everything out, test it well, and ensure performance. And no, I don't listen to benchmarks. I never run 1000 queries in my view because my ORM exposes objects directly to that layer, nor do I run "Hello World" in a loop from my controller. By the time an application gets to be any sort of complex, the speed of the framework is largely overrun by whether it was easy to write the code in the first place.
- **My own experience**: I have first-hand experience with many other PHP frameworks - I work on a Symfony codebase for a living, have done freelance with both Zend and Lithium, have had to rewrite CodeIgniter apps - and I just plain like CakePHP.
- **It's not Symfony**: I have a bit of a distaste against all things French, Symfony, and Baguette-like. Actually I love the outer two, but I have personally never had a great Symfonic experience. YMMV, and this is just my opinion ;)
- **Patriot Ale House**: A bit of an inside joke, but I don't trust any developer that has not been to this bar and had a pint of Patriot Ale.

I will say that there are lots of interesting things going on in other frameworks, but most of them just remind me too much of bloat, too much of Java, have too much configuration management going on, and think about too many layers of abstraction for me to want to deal with.

At the end of the day, I want to write code, and I applaud all developers doing the same, regardless of the language, framework, or tooling they use.

Pick a framework and ship something.

* Jose Diaz-Gonzalez
* CakePHP Core Troll
