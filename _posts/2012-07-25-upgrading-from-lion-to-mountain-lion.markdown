---
  title: Upgrading from Lion to Mountain Lion
  category: Installation
  tags:
    - development
    - mountain-lion
    - os-x
    - upgrade
  description: A guide to fixing all the breaking php and ruby packages in Mountain Lion
  comments:    true
  sharing:     true
  published:   true
  layout:      post
---
Lots of things broke.

The installer restarted my machine, went through the install process, and then went through the install process again. Wut?

Boots into OS X, and my terminal takes FOREVER to boot. Fixing permissions on the `/usr/local` directory fixed most of that:

```shell
sudo chown -R `whoami` /usr/local
```

Next up was upgrading XCode, which took an hour to download/install. Installed the CLI tools as well.

Chrome was busted, kept having weird issues with it's cache retrieval, and not properly formatting pages I had in cache. Just clear your cache bro.

PHP was broken, both in Apache - Web Sharing went away as an option... - and in CLI - derped about a dynamic library not being linked in.

```shell
brew update
brew outdated|xargs brew install
brew tap homebrew/dupes
brew install apple-gcc42
```

Now I'm cooking. `foreman start` in our work repository failed, some error about Java needing to be installed to run ElasticSearch. Thankfully, OS X showed a prompt to download and install that.

Now I tried to reinstall php54. `brew install php54 --with-mysql` failed, with errors about not having `png.h`. Installing `libpng` from `homebrew-dupes` was unhelpful, but searching online brought up the fact that X11 is needed for that library - some people had issues installing Imagemagick, and installing [XQuartz](http://xquartz.macosforge.org/landing) fixed the issue.

```shell
brew install php54 --with-mysql
# re-enable php in apache's httpd.conf
sudo apachectl start
```

It also derped on my virtualhosts. VirtualHostX usually sets this up. I simply had to re-include the vhost.conf file in my `httpd.conf`

RVM shit itself:

```shell
/Users/jose/.rvm/gems/ruby-1.9.2-p318/gems/eventmachine-1.0.0.rc.1/lib/rubyeventmachine.bundle: [BUG] Segmentation fault
ruby 1.8.7 (2012-02-08 patchlevel 358) [universal-darwin12.0]

Abort trap: 6
```

This is for things that are compiled against certain libraries. Eff this, uninstall ALL the things.

```shell
rvm implode
```

Now reinstall that fucker using [Jewelry Box](http://unfiniti.com/software/mac/jewelrybox) and laugh maniacally as you type out `bundle install` in ALL the things.

Wait, it broke. Alright, lets try `rbenv`?

```shell
brew install rbenv
brew install ruby-build
rbenv global 1.9.2-p290
```

Now to gem install ALL the things!

```shell
# in your project dir
bundle install
```

If you are depending upon something like Imagemagick, you'll need to reinstall:

```shell
brew remove imagemagick
brew install imagemagick
bundle install
```

Lets run brew doctor:

```shell
brew doctor
```

Fix ALL the bugs.
