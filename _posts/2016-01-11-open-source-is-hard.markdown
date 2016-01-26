---
  title:       "Open Source is Hard"
  date:        2016-01-26 12:00
  description: "Why I find writing and maintaining open source to be extremely difficult"
  category:    rant
  tags:
    - rant
  comments:    true
  sharing:     true
  published:   true
  layout:      post
  disable_advertisement: true
---

Writing code isn't very difficult. Usually you write something, it mostly does what it needs to do, and you carry on with your day. If you writing code for work, it might go through some review, or you may just ship it out to whoever your users happen to be. If you are writing code for open source, that's where it gets tricky.

## What is open source software?

I'll loosely define open source software as any piece of software wherein the author(s) provides a copy of the source code to run a piece of software, as well as a license stating that others are able to use it for any purpose.

Sometimes that source code might result in a binary - for instance, if you are compiling a game application, or a console executable. In many cases, web developers end up using the source code directly, such as in non-compiled rubygems, or npm packages for nodejs. Backend developers might use compiled versions of software for datastores such as MySQL or Elasticsearch. *Usually* there is an easy way to transform the provided source code into a finished product.

The license might have some limitations - you might not be able to sue me, for instance, or I might require that you release any modifications as open source as well. There are a myriad of licenses, each with caveats or reasons why you might favor it as an individual but be opposed to it as a company.

> There are an equal number of explanations as to why a particular license is suitable for your next open-source project, so investigating them is an easy way to waste a weekend. [tldrlegal](https://tldrlegal.com/) seems to be a legitimate website that explains commonly used licenses.

## What is an open source project?

An open source project differs in a way from open source software. For instance, I might have the following bit of MIT-Licensed PHP code:

```php
<?php
/**
 * The MIT License (MIT)
 * Copyright (c) <year> <copyright holders>
 *
 * Permission is hereby granted, free of charge, to any person obtaining
 * a copy of this software and associated documentation files (the "Software"),
 * to deal in the Software without restriction, including without limitation
 * the rights to use, copy, modify, merge, publish, distribute, sublicense,
 * and/or sell copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 * DEALINGS IN THE SOFTWARE.
 */

echo "lolipop\n";
?>
```

The above software, when executed, prints `lolipop` with a newline to the screen. You can run it locally under your version of PHP and it will probably work fine. YMMV and all that jazz.

An open-source *project* typically also has the following:

- The above code is in a repository somewhere.
- There is an issue tracker where users can report bugs.
- There is documentation concerning the installation and usage of the software.
- There might be test cases for this software.
- The project has actual maintainers, instead of authors, who steward the project for it's "lifetime".

An open-source project requires more effort on the part of maintainers to ensure that the project is kept up to date, continues to evolve as necessary, and issues are responded to where required.

## Things a good open-source project does

A good open-source project does the following:

- Writes well-written, ever-evolving documentation.
- Keeps a roadmap for users to understand how and where the project is changing.
- Responds to issues that are reported by users, and:
  - Fixes bugs as they arise.
  - Limits the scope of the project when enhancements are requested.
  - Implements feature requests where possible.
  - Points users the right piece of documentation for their issue.
- Provides multiple methods of providing live support. This can be any of the following:
  - Forums
  - IRC/Some form of live chat
  - Mailing list
  - Stackoverflow
- Proactively deals with issues that were brought up via social media.
- Has detailed onboarding information for new members of the core team, and revises them as necessary.

A good open-source project is run like a business, because that is what they are. All the things a company does to survive are things successful open-source do on a daily basis. These things matter because the perception of an open-source project is based upon all of these items, and - other than personal need - that perception is oftentimes the only thing keeping the project alive. No one wants to work on an unused piece of software.

## How to crush the soul of an open-source project maintainer

I personally have a very large backlog of projects I'd like to work on for a myriad of reasons:

- personal gain
- beneficial to a specific community
- requirement for an upcoming work project
- it is something that I find interesting

Given that, I tend to start projects, work on them until they fit my needs, and then move on. I'll also attempt to provide usage documentation and a way to reach out to me. And that is when the problems start.

A user will happen across my project, see that it appears to be well-maintained and easy to use, and start using it. At some point it might not fit their requirements, so they file an issue with bugs or enhancement requests. Responding isn't so bad when you have a few small projects, or when you have a large project that has a few users. The issue is magnified when you start having multiple projects with many distinct users who each _expect_ changes to occur. For free.

Open-source projects tend to be unfunded.

People say any of the following things:

- Don't offer it for free if you cannot support it.
  - I open-source projects so I can get a new set of eyes on something, which is beneficial for both myself and the community that ends up using it.
- Ask for donations.
  - Developers do not donate money for code as their companies do not normally provide stipends for this.
  - Companies usually only ever "pay" for open-source in order to receive a license that they can use without being sued. When was the last time your company sent a donation to Debian or the Apache folks?
- Require payment for support.
  - Now you are some greedy douchebag and you will receive hate-mail.
- Add more users as co-maintainers.
  - *Sometimes* this works, but honestly now you have to manage both an internal community and an external community. Try doing this for a half-dozen projects, it doesn't scale.

It's quite common to see open-source developers quit their communities for a while once they see a barage of issues coming their way with little to no benefit for them.

> Note that your work *may* be generous and allow you to work on OSS during work hours - 20% time anyone?. Mine at least does not complain if I spend a few minutes responding to something on Github. Some people are not so lucky, and might even find that their work wants to keep the IP of your outside projects, even if it wasn't made on company hardware, etc. YMMV.

### Lazy/Greedy Developers

A good developer is lazy. They will go online, find some code that mostly does what they need it to do, hack at it until it does the rest, and move on.

A small percentage of users that have issues will file an issue asking for an enhancement or a bug fix. An even smaller percentage will provide a fix for that issue, or a patch that includes their enhancement. And the odds that the code provided is up to the standards of the project *and* is in the scope of the project is pretty-well close to zero.

Of those that don't provide a fix, there is a very large number of people that *expect* the code to be written for them. Sometimes this is a case where there is a language barrier, but oftentimes developers just assume that what they want will come for free and it will be implemented quickly. Their project is way more important than yours, and they are [providing you an unpaid service by giving you feedback](https://github.com/JuliaLang/IJulia.jl/issues/398). And they are [actively hostile](https://github.com/plataformatec/devise/issues/3834) when you [attempt to provide answers](https://github.com/plataformatec/devise/issues/3832) to their questions. The number of entitled developers online is outrageous.

And people continue to be surprised that demand for free labor outstrips supply.

> This is a common pattern I've seen in many organizations, where people don't complain loudly when things are broken because they expect no movement from people that can help. So they trudge along with semi-broken experiences, because they are under some deadline and in many cases don't feel like fixing an issue themselves.

## How do we fix it?

We don't. You could try being a bit nicer to your open-source maintainer, perhaps send them a few bucks if they really saved your bacon, but honestly if a project like OpenSSL [cannot get more than a couple thousand](http://arstechnica.com/information-technology/2014/04/tech-giants-chastened-by-heartbleed-finally-agree-to-fund-openssl/) in funding a year, it's highly unlikely that a project maintainer will see any sort of monetary gain from their projects.

There are ways you can support developers. For instance, I might one day make a whole $10 dollars from [Gratipay donations](https://gratipay.com/~josegonzalez/), which is enough to buy two of the three venti mocha fraps I drink a day. There is also [flattr](https://flattr.com/), but I honestly have no idea how to use it. Definitely some room to improve, here, though if the OpenSSL people can't get the money they *actually* need, I don't have a snowball's chance in hell of receiving a meaningful amount of donations to feed my cat.

The only thing I can think of is, well, going back to charging for software. Having a paid software ecosystem around your projects seems to work nicely for those that can manage it. Certainly possible for some larger open-source projects - [there](https://www.elastic.co/) [are](https://www.mongodb.org/) [many](https://www.sugarcrm.com/) [startups](https://convox.com/) [focused](https://www.docker.com/) [around](https://www.joyent.com/) [this](https://about.gitlab.com/) [model](https://www.nginx.com/) - though I wonder how easy it would be for the every-day developer to start off.

> Providing software support packages could also work, but now you are just consulting. I write open source code because it's fun, not because I want to do work.
