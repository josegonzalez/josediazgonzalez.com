---
  title:       "CakePHP Advent Calendar 2014"
  date:        2014-12-01 17:24
  description: "Introducing a slightly different CakePHP Advent Calendar."
  category:    cakephp
  tags:
    - cakeadvent-2014
    - cakephp
  comments:    true
  sharing:     true
  published:   true
  layout:      post
  series:      CakeAdvent-2014
---

Last year for the Advent Calendar, I brought to you [25 delicious posts](/2013/12/01/testing-your-cakephp-plugins-with-travis/) surrounding writing better CakePHP applications. Those posts catered to both the beginner and advanced CakePHP developer, and hopefully can still be of some use to you.

This year, however, we're going to kick it up a notch and actually use our skills to design 3 custom [CakePHP](http://cakephp.org/) applications:

- An anonymous markdown-based issue tracker capable of sending email notifications and exposing webhooks
- A simple cart system with user authentication and payment processing
- A simple tumblr clone with support for post type extensions

## A bit of background

As some of you may be aware, [CakePHP 3](http://bakery.cakephp.org/articles/markstory/2014/11/17/cakephp_3_0_0-beta3_released) is right around the corner. With just two RCs left, it's almost ready for prime-time with lots of great changes. Unfortunately, this also means that some of the old knowledge we had is no longer applicable, and so rather than try to introduce CakePHP 3 features in one-off tutorials, we will showcase the power of the new framework to build working applications.

## Why 3 tutorials?

CakePHP 3 is coming out, so we should match it with the same number. It also helps that an Advent Calendar is 25 days, so we'll have an interlude between each tutorial series.

## Who are these tutorials aimed at?

You should have some knowledge of the PHP language, and knowledge of any MVC framework will help. That said, new CakePHP developers will hopefully grow more comfortable as we progress with the tutorials.  We'll be laying the foundation for effective application development - via working local development environments and production code deployment.

For experienced CakePHP developers, these series of tutorials will be designed to point out changes from the 2.x series. Note that we'll be a bit light on tests - this is a purposeful change to make following the tutorials a bit easier, but don't be afraid to practice TDD.

For CakePHP haters, these tutorials are meant to show development practices in another framework. We will be using community libraries where possible, and thus most of the applications we are building will be possible to build in other frameworks. As CakePHP 3 is quite modular, you are welcome to incorporate both developed application code as well as CakePHP 3 libraries in your non-CakePHP projects.

## What do I need?

These tutorials are completely free, and there will be no cost for any of the tools we use (other than your computer!). You'll want to setup the following before reading these tutorials:

- A [Github account](https://github.com/)
- A [Heroku account](https://www.heroku.com/)
- Install [Git](http://git-scm.com/) if you are not on a Mac
- Install [Vagrant](https://www.vagrantup.com/)
- Install [Virtualbox](https://www.virtualbox.org/) or [Vmware Fusion](http://www.vmware.com/products/fusion)

Please ensure you have all of the above setup, as otherwise certain portions of the tutorials will not make sense.

Note that not every tutorial will use the above tools, and you are free to use alternatives if you so desire.

## How do I get started?

I'll be posting new posts in the series each day of the Advent Calendar, and tweeting about it as [@savant](https://twitter.com/savant). If you'd like to subscribe to this blog, you may follow the [rss feed here](/atom.xml). Also, all posts in the series will be conveniently linked on the sidebar of every post in the 2014 CakeAdvent Calendar. Come back tomorrow (if you're reading this on the 1st of December!) for more delicious content.
