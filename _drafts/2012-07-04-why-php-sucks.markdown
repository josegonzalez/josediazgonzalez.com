---
  title:       "Why PHP Sucks"
  date:        2012-07-04 14:07
  description: PHP sucks so bad it is used for pageviews alone
  category:    PHP
  tags:
    - php
    - sucks
    - pageviews
  comments:    true
  sharing:     false
  published:   false
  layout:      post
---

Lately I've been reading plenty of posts regarding PHP's inability to:

- scale
- evolve
- fix bugs
- generally not suck

## The facebook argument

I've never worked at Facebook. Personally, they could write their codebase in [Arc](http://arclanguage.org/) and I would be none the wiser. We would likely have an Arc to C++ compiler at the moment. The only thing different from that reality and this one would be that no one would use Facebook to show that PHP either scales/does not scale.

The reality of the matter is that their developers write in a subset of PHP - not even an up to date one, as at the moment I don't think HipHop or it's derivative support namespaces or closures - for their day to day work. They likely have slightly different C extensions for various common code, such as outputting date information or searching for usernames in strings. At the end of the day, when someone pushes deploy, a gigantic C++ binary gets deployed to their servers.

The cool part about this is that PHP was with them until late 2009, and even in late 2010 they still had some [raw PHP in production](https://developers.facebook.com/blog/post/2010/02/02/hiphop-for-php--move-fast/). Not bad for a cat-photo-sharing site.

No one ever says that deploying JRuby code is actually deploying Java code, yet that is what is happening here with Facebook's HipHop. The underlying Ruby interpreter was replaced with a JIT compiler and just so happens to be eleventy-times faster[1]. Same with PHP and HipHop. The codebase is the same, and can probably run on a commodity server, but the deployed code is quite a bit different.

Most of your cat-photo sharing sites will never need to be rewritten to handle the sort of load they do. And it doesn't matter. Facebook developers will continue to write PHP code because it is easy to read and understand, and therefore they do not need to teach an already brilliant developer how to use slots, self, and general metaprogramming in Python. They can take one who is great at writing Java code and throw him at a PHP codebase and he'll be fine. Same with C++, Ruby, Objective-C, whatever. All those developers will be fine in PHP, and will be writing code earlier than if there was a lengthy training period.

Facebook may not be deploying PHP code, but they sure are writing it. So stop making [faulty generalizations](http://en.wikipedia.org/wiki/Overwhelming_exception) about PHP based upon the deployment of a single application.

## On logical fallacies

Most of the attacks begin with the typical [ad hominem](http://news.ycombinator.com/item?id=4198333) fallacy, wherein:

{% blockquote http://news.ycombinator.com/item?id=4198333 %}
Congrats, PHP has a package manager. This does nothing to shake my feeling that PHP's most ardent advocates have little hands-on experience with the more full-featured alternatives. You know, like the ones that also have decent package management without PHP's baggage and limitations.
{% endblockquote %}

Personally, I've never used [Python for anything useful](https://github.com/josegonzalez/scrapilicious). Hell, I've never even [monkey-patched a useful Ruby project](https://github.com/josegonzalez/cimino/blob/master/_plugins/_extensions/themes.rb). Fabien Potencier would NEVER use [python for anything related to the Symfony Framework](https://github.com/fabpot/sphinx-php). Heaven forbid a [PHP framework developer knew a little C](https://github.com/jperras/fastium). I could go on about how PHP developers know nothing of any other languages, and that is why PHP frameworks don't share anything with stuff like Jinja2, Flask, Sinatra etc.

If you're going to argue that PHP developers don't know dick about shit, please do a little research first. It is kind of annoying to have someone say that any PHP "apologist" must never have worked with any other language. That is categorically false. I deploy PHP, Ruby, Python all day long. I've built a web-service or two in Python, and maintain [homebrew-php](https://github.com/josegonzalez/homebrew-php), which just has to be written in Ruby. Whenever I read one of these blog posts about how I must not ever work with anything but PHP, I feel a rage inside me that commands me to choke the life out of those writers using the hundreds of Chef recipes I've written over the past 2 years.

No, I am not an outlier. I can assure you that any of these framework developers have used other languages where it is appropriate. I would not write PHP for a financial firm, nor would I write an event-driven service in PHP. I would likely write them in Java and Python, respectively. But by and large, all of these people realize that PHP - using a framework, of any kind, something to enforce standards across a codebase - can actually get things done.

As an anecdote, I would estimate more than half of `$DAYJOB` is written in PHP, and the other half is written in whatever language/framework is best suited for the task. And no, I do not work for a cat-photo sharing website, and yes, I have dealt with AWS outages for reasons other than "PHP does not scale".

## On fixing bugs

[Everything](http://bugs.python.org/) [has](http://bugs.ruby-lang.org/) [bugs](http://code.google.com/p/go/issues/list). [PHP does too](https://bugs.php.net/). That is the nature of software. Some bugs are fixed immediately, and others take time due to legacy code.

What I don't really understand is taking the stance that PHP never fixes bugs, and then reversing that when they do actually fix bugs. For reference, here are the Hacker News PHP trolls taking both stances:

- http://news.ycombinator.com/item?id=4145179 (Write better code and test it)
- http://news.ycombinator.com/item?id=4187805 (Internationalization is hard)

On the one hand, we have a developer who decided to move two whole versions away - PHP 5.3 should just have been PHP 6 tbh - and then complains about how his 3 year old project no longer works because he was passing around nulls.

Lets forget about the fact [Null References are a Billion Dollar Mistake](http://qconlondon.com/london-2009/presentation/Null+References:+The+Billion+Dollar+Mistake). Shit will almost certainly break if you upgrade your langauge that far up. Even in the Ruby 1.9 series, I have had perfectly fine code on a trivial codebase break when moving from 1.9.2 and 1.9.3. All the gems that broke - you thought it was MY code with bugs, didn't you? - broke for trivial reasons, but reason enough for me to downgrade. And this is a normal occurrence.

And when PHP can't fix an old bug? You may as well ring a PHP troll bell, because they all come running as if pigs to a slaughter. Writing code is hard enough, and the choice to make identifiers case-insenstive may have been a good one in certain contexts - you just write mediocre PHP code and it makes you money - but it definitely is a PITA if your written language does funny things to characters. I'm not saying there is an easy fix - no one wants to hardcode a path in a large codebase, that's asking for trouble - but it's not like the PHP developers didn't think at all about the problem once it was reported. I'm sure one of them got really upset and probably needs a new liver right now.

### Lessons learned?

- When you upgrade Language versions, be aware of subtle changes in operation. Not all changes are documented, or even known.
- Stop passing around nulls/nils, that is bad in any language.
- Internationalization is hard as fuck, and any developer that thinks they can solve it once and for all is completely clueless.
- Stop picking on PHP and write some fucking code

## On PHP's sloppiness and writing useful things

I will be the first to admit that I can never remember the order of arguments in `string` or `array` functions. I also always forget that order when using the `link` resource in chef, or `ln` on the command line - blanking out configuration files in production because you did `ln -sf` always leaves me with a shitty feeling in my stomach.

I also hate that some functions are `underscored` and others just `smashshittogether`. One of the devs at work complains about how ugly writing PHP looks, but then flip-flops on using two or four spaces in his Python code.

One thing I super-duper hate is when developers use the `mysql_` functions directly instead of something like PDO. Except I did that when writing some healthcheck code last week. Oh how much I hate myself.

I ABSOLUTELY hate it when PHP developers mix their data/request/templating code all into a single file. Reading WordPress code makes me want to stab myself in the eyes, and anyone at `$DAYJOB` knows I will complain loudly when assigned some WordPress related task.

We get it, PHP's standard library sucks balls, [you can't do anything](http://www.wikipedia.org/) [useful with it](http://www.extremetech.com/computing/123929-just-how-big-are-porn-sites?print), [it's only for cat-photo sharing sites](https://www.facebook.com/). If you want to start a sharing site for designers and developers, you probably [shouldn't build your site in PHP](http://forrst.com). [No serious developer would have ever used PHP for anything ever](https://groups.google.com/forum/?fromgroups#!msg/cake-php/lhHExSrYTRo/i4dC2oIdrEsJ).

The api has warts, and this is understood by any active PHP developer. We won't lie when we say some things aren't as fun to write in PHP, but are better suited for X. I'm more than happy to say I won't write websocket code in PHP. I wouldn't write websocket code to begin with, and you probably won't either, so who the fuck cares?

If it's so sloppy and you cannot stand PHP, here is a list of code you should stop using immediately:

- Cacti (I hear Graphite is awesome though)
- PHPMyAdmin (Fuck guys, it's in the name)
- Wikipedia (Stop learning)
- Wordpress (Yes, you SEO fucks that can't code but can complain about PHP should also stop blogging)
- Bugzilla (Use redmine instead)
- phpBB (and any forum run on it, which is essentially every forum)
- Magento (actually, stop using it anyways, developing for it requires a PhD in Computational Linguistics)
- Horde (your Universiy probably runs this)

If you really want PHP to die because one does not simply write useful software, then you should stop using anything written in PHP immediately.

## On PHP alternatives

There are no realistic alternatives for PHP. At least in the startup community, there is this idea that only a completely webscale, Redis/MongoDB, NodeJS-based architecture will be successful. If your app is using [Symfony](http://seatgeek.com/jobs/web_engineer/) or Zend, the [competition built on rails](http://www.fansnap.com/jobs) is going to eat you alive \**potshot*\*.

The truth is that developers are actually doing real work with PHP. Same with Python, Ruby, Objective-J, Visual Basic etc. Real work that involves actual money.

Write your web applications in whatever language you find useful, but when your developers cost twice as much because they are NodeJS Ninja Rockstar Gurus, and then you're completely dominated by a small team of developers who happen to write PHP, remember that HN will always be there for you to say PHP blows monkey chunks.

PHP isn't great, and it's not the best at most things, but it's paying the fucking bills.

## Notes

[1] Eleventy isn't a number. JRuby is actually Umpteen times faster.