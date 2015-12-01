---
  title:       "Work Items"
  date:        2014-11-16 19:47
  description: "Big projects I will screw up over the next few months"
  category:    dev log
  tags:
    - development
  comments:    true
  sharing:     true
  published:   true
  layout:      post
---

Areas of active interest over the next few months. This is a brain dump, and a much better way of tracking wtf I want to do than the current todo-list method I've been using. I doubt I'll get half this crap done.

## Software as a Service

Some day I would like to have tens of dollars come into my bank account every month. Here are two pieces of software I am writing in the hopes that people will want to pay me:

- Writing a SaaS Wiki platform.
  - Needs some sort of inline wiki editor. Haven't looked too hard, and I figure I could write one if need be.
  - Need to extend the markdown parser (cebe/markdown) to support lots of extensions useful wiki extensions. Yes, it's markdown based, and yes, I realize you can use a Github repo/wiki or something instead. Or an existing wiki solution.
  - Should probably hire people to audit cebe/markdown for security issues
  - I need a better styling than the bullshit I came up with when drunk. Not that it's bad, but I was drunk.
- Writing a SaaS Book Editing tool.
  - I originally wrote one to make it easy for me to allow people to edit my own book, and I figure it might be useful to other people.
  - Needs to support context for comments
  - Missing comment notifications
  - No way to currently mark a comment as "resolved", which makes it a pita to have to review old comments.
  - Need to support giving users access to books as well as limiting them to certain chapters. Currently I need to insert a database record, and that won't work in production.
  - Need to support multiple "owners" of a book. Maybe like book organizations or something. Might need to rework the permission system.

## Fun side projects

- A yes/no domain hosting platform. You point a domain at the yes/no generator, pay $10 a year, and get stats/an api to switch the yes/no to something else.
- [humanslol.org](http://humanslol.org/) needs to be a thing.
- Making [more 8-bit paintings](https://twitter.com/savant/status/520684357946994688).

## Blogging

- CakeAdvent 2014 is going to be a thing - [last year](/tags/CakeAdvent-2013/) was tres excellent - and I'm currently gathering material
- Bringing back my [daily dev log](/tags/daily-dev-log/) in some fashion. It helped me formulate my plans - most work ended up being spread out over a series of a few days.
- A few tutorial posts I started but never completed, plus things people ask about in my issue tracker.
- Writing more tutorials on operations-type things, which will give me an excuse to learn how to use said tools.
- Updates to my blog to make discovering content a bit easier, as well as styling and blah blah fucking blah.

## Books

I'm writing/rewriting a few books, mostly on CakePHP.

- A book on using [Python Fabric](http://www.fabfile.org/) for various things.
  - Based on some of the things I've done at work/to support work.
  - Using it as an api, writing custom decorators, integrating with AWS, fixing logging, writing Web UIs, etc. Should be a small but fun one.
- Updating my [current CakePHP book](/cakephp-book/) to 3.x.
  - I'm about half-way done, but need to redo certain chapters as the CakePHP apis change a bit in certain cases.
  - Want to also add two new chapters:
    - Versioning Pastes
    - Adding a simple api with oauth integration
- Converting a tutorial series to CakePHP 3.x.
  - The original writer has given me permission, just need to actually write the content.
  - Aimed towards intro CakePHP users, so different target from my first one.

## Open Source

As always, I'm heavily involved in both my own and community projects. Poop.

- [Beaver](http://beaver.readthedocs.org/) needs a whole lot of love :( . I wish I had time to work on it/improve it, as I learned a lot during the process and I know there are things I can improve.
- I started helping maintain [Dokku](https://github.com/progrium/dokku) - a single-server heroku alternative.
  - The original maintainer was burned out I guess. NBD, shit happens. I think he's starting to pickup some steam, so hopefully we can continue on with this.
  - Lots of pull requests and issues to triage. I closed ~60 issues and merged ~19 pull requests over the past week. My goal is zero bugs by the time we hit our 0.4.0 release, so stabilizing the external api is pretty important.
  - I personally made 22 commits over the past few days. It's been a good way to exercise my bash-fu.
  - Tests still fail, and I don't have access to the webserver that runs them or even the script that handles test-running :( . We'll get that sorted out though, I'm sure.
  - I'd like to write a simple web ui for it and integrate it with AWS services - RDS, ElastiCache, backups - and potentially sell that web ui as a product. Not that anyone would/should buy it. I've always wanted to write web tools to automate servers...
- Lots of [CakePHP open source](/open-source/)...
  - Move [friendsofcake/vagrant-chef](https://github.com/friendsofcake/vagrant-chef) to support more of a heroku-style deploy for any PHP framework. Would be extremely nice if users of the project could just have their framework auto-detected and be able to work.
  - Work on [friendsofcake/crud-view](https://github.com/friendsofcake/crud-view). I started a while back, but it needs a lot of love and a dedicated developer. It's basically scaffolding on steroids.
  - Updating a bunch of plugins to CakePHP 3.x.
  - Marking a bunch of plugins as deprecated and pointing users to alternatives
  - Adding support to filter out 3.x from 2.x plugins on the CakePHP plugins site
  - Making a new version of the [friendsofcake/app-template](https://github.com/friendsofcake/app-template/) project for 3.x. Much simpler now that CakePHP 3 has built-in support for using DSNs for connection strings, but still has to be done at some point. Will be necessary for my book.
  - Contributing cli-based migration generation for [phinx](https://phinx.org/). We have r[ails-like migration generation](https://github.com/CakeDC/migrations/blob/master/Docs/Documentation/Generate-Migrations-Without-DB-Interaction.md) in CakePHP 2.x, but now that we're adopting a community library, we need to port that feature. Won't be hard as the basic structure is already there.
- Generic PHP queuing library.
  - I already have a version I stopped working on last year called [php-queuesadilla](https://github.com/josegonzalez/php-queuesadilla), though it needs some love and care before it can be considered general use. It also needs to use proper queuing systems (rabbit and zero are missing).
  - All the existing ones suck or pull in quite a few requirements.

## Work-related stuff

There's other, more important crap, but one does not simply post all the things. The stuff here will likely be open source if it already isn't.

- An integration between ruby's ERB templates and consul. Should let me re-use chef templates rather than needing to maintain them in two places.
- Make it easier to interact with [cronq](https://github.com/seatgeek/cronq), a distributed cron-like system. Also have a few logging improvements to make, and the codebase isn't the greatest thing...
- Making [graphite-pager](https://github.com/seatgeek/graphite-pager) scale slightly better, perhaps by rewriting it to be a statsd clone so that it can introspect on data rather than retreiving it during a check.
- Clean up a php-aqmp job system we have (unrelated to my own open source work). You know, to be good open-source citizens.

#### tl;dr I'm hella busy
