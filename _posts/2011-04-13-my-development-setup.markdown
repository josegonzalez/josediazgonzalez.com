---
  title: My development setup
  category: Installation
  tags:
  description: For the purposes of archiving how I like to develop, I'll chronicle a few things here.
  comments:    true
  sharing:     true
  published:   true
  layout:      post
---

For the purposes of archiving how I like to develop, I'll chronicle a few things here.

First things first. You'll want to ensure that your login/non-login terminal sessions have the same environment. On OS X, non-login sessions use the `~/.bashrc`, while login sessions use `~/.bash_profile`. Most terminal emulators follow this rule, but lets ensure this is always the case by modifying our non-existent `~/.bash_profile` as follows:

```shell
if [ -f ~/.bashrc ]; then
  source ~/.bashrc
fi
```

Whenever something asks you to modify your `~/.bash_profile`, ensure that the modification is in your `~/.bashrc` instead. This will help debugging down the road.

Install XCode. For Lion/Mountain Lion, it is important that you also install the `Command Line Tools`, as the version of `gcc` that is included with XCode 4.3 is incompatible with certain build tools.

XCode 4.2 users - that means anyone on Snow Leopard - should install the [osx gcc installer](https://github.com/kennethreitz/osx-gcc-installer), as installing a proper gcc is pretty much impossible otherwise.

Once that is complete, install homebrew - the proper way, to `/usr/local/`, with no sudo enabled:

```shell
/usr/bin/ruby -e "$(/usr/bin/curl -fksSL https://raw.github.com/mxcl/homebrew/master/Library/Contributions/install_homebrew.rb)"
brew update
brew install bash-completion
```

Then you'll want to have RVM installed:

```shell
bash -s stable < <(curl -s https://raw.github.com/wayneeseguin/rvm/master/binscripts/rvm-installer)
```

The following will ensure `rvm` is always loaded. And add the following to the bottom of your `.bashrc`:

```shell
[[ -s "$HOME/.rvm/scripts/rvm" ]] && . "$HOME/.rvm/scripts/rvm"  # This loads RVM
```

Then source your `~/.bash_profile`

```shell
source ~/.bash_profile
```

Be sure to run the following and follow any instructions:

```shell
rvm requirements
```

If you are running a version of `rvm` less than `1.12` on Lion/Mountain Lion, you will need to install the [osx gcc installer](https://github.com/kennethreitz/osx-gcc-installer) due to a bug in `rvm` itself. It should be fixed in `1.12`.

Then install the desired rubies. I leave `1.9.2` as default, which is usually safe now:

```shell
rvm install 1.8.7
rvm install 1.9.2
rvm install 1.9.3
rvm install ree
rvm use --default 1.9.2
```

You can now install any gems you typically use. I would recommend leaving this to `bundler`, and using a proper `Gemfile` in all your projects, however small they may be. You can use rvm to manage gemsets if necessary. Please read [the documentation on that](https://rvm.beginrescueend.com/gemsets/).

I usually install the following brews - follow all their individual installation instructions! - at this point:

```shell
brew install bash-completion git subversion bazaar mercurial mysql mongodb redis elasticsearch ack python nodejs imagemagick
```

Sometimes `subversion` installation freezes - haven't investigated this yet - so you can either install it separately, skip it, or just rerun the command. I generally kill it if it's been running for what seems to be 45 minutes.

I personally install `gsl`, so I can use `LSI` to generate related posts within [Jekyll](https://github.com/mojombo/jekyll) in conjunction with [Ruby-GSL](http://rb-gsl.rubyforge.org/). Homebrew comes in handy.

```shell
brew install gsl
```

If you get issues doing `gem install rb-gsl`, you probably want to install an older version of `gsl`, version 1.14:

```shell
brew remove gsl
brew install https://raw.github.com/mxcl/homebrew/83ed49411f076e30ced04c2cbebb054b2645a431/Library/Formula/gsl.rb
```

If you are using nodejs, you'll also want to install `npm`:

```shell
curl http://npmjs.org/install.sh | sh
```


If you've installed `python` using homebrew, I suggest doing the following so that installing python packages uses the right python:

```shell
# install pip
/usr/local/share/python/easy_install pip

# modify PATH in ~/.bashrc to have the following
export PATH="$(brew --prefix python)/bin:$PATH"
export PATH="/usr/local/share/python:$PATH"
```

Next comes the customization of PHP. I use PHP for most of my development - well, anything that has nothing to do with systems administration at least - so it's very useful to have an up to date version with a few different extensions. I've recently begun managing [Homebrew-PHP](https://github.com/josegonzalez/homebrew-php/), so I have the process down pat - again, follow any instructions for each brew, like enabling the homebrew `php` in Apache:

```shell
brew tap josegonzalez/homebrew-php
brew install php --with-mysql
brew install apc-php
brew install mongo-php
brew install redis-php
brew install xdebug-php
```

Configure `IPv6` to be `Link-local only` in `Network -> Advanced` on all interfaces you use on a regular basis. This will prevent Apache from being confused about your IP address and potentially borking any Geolocation code. You can leave this enabled if your Geolocation code takes `IPv6` into account.

Now I need to ensure I have all my ducks in a row, and I sync in my home directory scripts. My [gitconfig](https://gist.github.com/565837), my ssh keys, all sorts of yummy stuff.

For the record, my `~/.bashrc` ends up looking [a bit like this](https://gist.github.com/2223297). Feel free to modify that at will. Note that it currently does not show branches/tags/bookmarks for `bazaar` or `mercurial`. Patches welcome :)

I no longer use [Textmate](http://macromates.com/) religiously. I recommend using [Sublime Text 2](http://www.sublimetext.com/2) with whatever your favorite setup is. Someday I shall post mine. I did run the following command to make it easier to call `Sublime Text` from the terminal:

```shell
ln -s "/Applications/Sublime Text 2.app/Contents/SharedSupport/bin/subl" $(brew --prefix)/bin/subl
```

For those still using Textmate, I recommend installing the [Git-Bundle](https://github.com/jcf/git-tmbundle), and customizing the hotkeys. The [CakePHP bundle](https://github.com/cakephp/cakephp-tmbundle) is up next, as is the [GitHub bundle](https://github.com/drnic/github-tmbundle). I use [PeepOpen](http://peepcode.com/products/peepopen) to find files in my projects - supports regular expression lookups - which is developed by the awesome guys at PeepCode.

I'll then make sure all my projects are installed in their proper directories (under ~/Sites). Once that is through, I'll install [VirtualHostX](http://clickontyler.com/virtualhostx/), which I use to configure Apache VirtualHosts. At this point, once the default Apache setup is enabled in the `Sharing` panel of `System Preferences`, I have all my sites ready and rearing to go (assuming I've imported a backup of my virtualhosts).

Now I need all the browsers ever. Install the latest versions of [Chrome](http://www.google.com/chrome/), [Firefox](http://www.mozilla.com/en-US/firefox/new/), Safari, [Opera](http://www.opera.com/). Get [iPhoney](http://www.marketcircle.com/iphoney/), which lets you test mobile sites on an iPhone-like browser. My [Parallels](http://www.parallels.com/products/desktop/) vms get rsync'ed over, and I go through a very painful install of Parallels (gotta download their app from their panel). Test to ensure that all my vhosts are getting passed into my VMs, and then onto the next step.

[Skype](http://www.skype.com) and Adium are a must for chatting. Everyone has a different Adium setup - just copy your old profile for that ;) - but for Skype I use [version 2.8](http://www.skype.com/intl/en/get-skype/on-your-computer/macosx/2-8/). [Tweetie](http://www.atebits.com/tweetie-mac/) also deserves a mention here. The new Twitter for Mac is lame in that it follows me on every single workspace, but they may have fixed that since I last checked.

I also install [TotalFinder](http://totalfinder.binaryage.com/) and [Visor](http://visor.binaryage.com/). TotalFinder is like Finder but more boss, with tabs and everything. If you've ever played Quake, you'll know what Visor is. Drop-down terminal. Makes life easy.

I'll also install [Dropbox](http://www.dropbox.com/) for the 5 times I use it ever, as well as [CloudApp](http://getcloudapp.com/). CloudApp makes file-sharing easy, and I use it on a regular database to share screenshots with other developers.

I install [Pixelmator](http://www.pixelmator.com/) for quick and dirty image-editing, and Photoshop for things that my boss needs to be pixel-perfect. If Pixelmator could fully support Photoshop images, that would be sweet, but I guess we can't have everything. [iShowU HD](http://store.shinywhitebox.com/ishowuhd/main.html) is good for screencasting, and I'll also install [Silverback](http://silverbackapp.com/) for recording user interaction with a site/screencasting.

For Git tooling, I'll install [Git Tower](http://www.git-tower.com/), which is sort of like [Versions](http://versionsapp.com/) is for SVN. I'll also install GitX - use [Brotherbard's branch](https://github.com/brotherbard/gitx) from github - and [GitNub](https://github.com/Caged/gitnub), which provide some of the Git Tower features, but with a less-polished UI. Definitely an alternative for those not wishing to spend money. [Kaleidoscope](http://www.kaleidoscopeapp.com/) also works well for file diffing. I haven't checked out alternatives in that space, but there should be something roughly equivalent for free.

I typically need access to productivity software, so I grab my copies of iWorks and Office for Mac.

As far as utilities, I use [Transmit](http://www.panic.com/transmit/) for FTP, [Speed Download](http://www.yazsoft.com/) for downloading many files at once, [UnRarX](http://www.unrarx.com/) for rar files, [Split&Concat](http://www.xs4all.nl/~loekjehe/Split&Concat/) for concatenating large files I've downloaded off the internet (typically zips of large binary image files spanning several hundred megabytes), [uTorrent](http://www.utorrent.com/) so I can quickly get ISOs of Linux distributions - [Vagrant](http://vagrantup.com/) is a nice tool I'm playing around with - and [Sequel Pro](http://www.sequelpro.com/) for interacting with MySQL databases. [Omnigraffle Professional](http://www.omnigroup.com/products/omnigraffle/) deserves a mention, simply for the 7 or 8 times a month I use it when creating a schema for something I'd like feedback on.

What are you using?
