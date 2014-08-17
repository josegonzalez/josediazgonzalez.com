---
  title:       "Introduction to Chef"
  category:    Opschops
  tags:
    - deployment
    - chef
    - capistrano
    - cakephp
  description: This text is the first in a long series to correct an extremely disastrous talk at CakeFest 2011. It will also hopefully apply to more than CakePHP.
  comments:    true
  sharing:     true
  published:   true
  layout:      post
  series:      Full Stack CakePHP Deployment With Chef and Capistrano
---

{% pullquote %}
This text is the first in a long series to correct an extremely disastrous talk at CakeFest 2011. It will also hopefully apply to more than CakePHP.
{% endpullquote %}

Inspired by the blog post series [Building a Django App Server with Chef](http://ericholscher.com/blog/2010/nov/8/building-django-app-server-chef/), and [SeatGeek's](http://seatgeek.com) very own [Michael D'Auria](http://mindsifter.com/), I decided to stop screwing around with my server installation and automate the process.

Every so often, I have the need to move from one host to another, whether because the price of the host is becoming prohibitive, or another host has some features that the former did not. On occasion, I also need to setup new instances of CakePHP/Lithium/Zend applications for some side project, contract work, or for a friend who is afraid of systems administration. While I do enjoy the [Slicehost](http://articles.slicehost.com) installation guides, they sometimes either are out of date or don't have the requisite information for installing software. As such, each time I have to install a new instance, I do it slightly differently, or forget to update old instances with new software.

So I set about looking at automating the entire process. My first pass was using a set of bash scripts. We all know how lovely bash can be. It doesn't help that I don't really know too much bash, so it ended up being a bunch of shell commands being exec'd. Fun times, and fairly error-prone.

So I decided to look for existing tooling - fuck yeah open source - that would perhaps help me improve my workflow.

## Chef

{% blockquote %}
Chef is an open-source systems integration framework built specifically for automating the cloud.
{% endblockquote %}

This is mostly true. You can also use it for automating single servers.

If you're a web developer like me, you can think of Chef as a framework. It provides a couple common interfaces for things you might want to do:

- Creating Files
- Installing Software
- Configuring Applications
- Interacting with Services

And allows you to build resources on top of it's base to fully customize your setup. Let's go over some Chef vocabulary:

## Commonly Used Terms

Please note that there are other terms to get used to, but these will suffice for now

- DNA: A configuration file for your server. It may contain packages to install, recipes to be run, and general configuration for use in installation.
- Recipe: A set of instructions that uses the Chef DSL for package installation, maintenance etc.
- Cookbook: A collection of recipes that pertain to a server or set of servers. Note that you don't need to use all the Recipes in a Cookbook, just like a real cookbook with all sorts of delicious pastries.
- Resource: A cross-platform abstraction of a common server task such as package installation or version control interaction. For example, CentOS uses `yum` to install packages while Ubuntu uses `apt`, but you can refer to both of these using
- Templates: Files that are filled in by variables. These are usually `ERB` files, but if you've ever used a templating language, it's not that different (`PHP` counts!)

## How Chef Works

This is the general workflow:

1. You run a script on your local machine, something like `chef-server`. The actual command could be `lollipop`, so long as it runs the remote commands.
2. The `chef-server` script runs remote commands against a given server via ssh. This can include:
  - Installing Chef
  - Updating Base Packages
  - Copying files to the server
3. ???
4. Profit

## Steps Three

I sort of left step three out on purpose. What actually happens is a bit more complicated:

* The script should ssh onto the box, and hopefully copy your updated cookbook and `DNA` config to the machine
* Whatever pre-processing your script does is performed - this is wholly up to you
* Your script runs should ensure the `chef` gem is properly installed on the machine, otherwise you just wasted a lot of time
* Scrip runs the chef gem against your cookbooks and `DNA` config.
* Your `DNA` config file, be it `chef` or `ruby`, is parse and compiled. If this fails, you should probably validate that it's good `json` or the `ruby` file parses
* Packages specified in your `DNA` file are installed according to the architecture of your server. If you're using CentOS ==> `yum`, Gentoo ==> `portage` etc.
* Recipes are run in the order specified in your `DNA` config file.
* If any recipe fails, Chef aborts, otherwise it continues happily until done. You get some lovely debug info in both cases.

Okay, so not so complicated, but decently enough that it's a 12-step process now, like Alcoholics Anonymous.

**To Be Continued**
