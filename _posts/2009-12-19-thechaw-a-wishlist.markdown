---
  title: The Chaw - A Wishlist
  category: CakePHP
  tags:
    - cakephp
    - thechaw
    - project management
    - wishlist
    - side projects
  comments:    true
  sharing:     true
  published:   true
  layout:      post
---

Looking at thechaw.com to handle my project management needs (on a related note, I'll be doing less of this although its still a problem I want to look at. Anyone need a developer in the NYC area? I work for chump-change!) Regardless, here is a list of things I'd like to see happen, and my thoughts on the whole matter (ignore any stupidities herein). I'm probably going to go through and do one or two of these myself as plugins, but ymmv everyone.

## Tickets

 - One should be able to define what a ticket means for a project/installation. So if we need more or less fields, we can define this per installation and refine it per project as the definition cascades down
   - Because of this, maybe it would be best to use something like MongoDB or CouchDB in order to store data. Or as an alternative to MySQL
 - Searching tickets should be either the ticker block that exists, or a search text box that takes a search syntax.
   - "priority:low (assignee:me OR assignee:gwoo) type:enhancement (-status:closed AND -status:on_hold)"
     - Would find all "enhancement" tickets with a "low" priority with the assignee either "me" or "gwoo" and without the statuses of "closed" or "on hold". Searching status defaults to only open tickets (or whatever we define per project), and any other types of search can be defaulted as well
 - Option to change the markup from Markdown to Textile or RST etc.
 - Option to turn off the WMD Markdown Parser
 - Attaching files, and showing those attachment both inline (Trac-style) and in a sidebar (CodeBaseHQ-style).
   - Attachments can be done with a ticket update or by themselves. Lightbox-style popup for just attaching files vs with ticket update
   - Multiple attachments at one time, even when creating a ticket. If ticket isn't created, then those files are not referenced by anything and some garbage collection tools runs that deletes them after some set period of time
   - ICONS! For uploaded ticket files. I'm thinking something like http://www.stdicon.com/crystal/ . Don't know the license and whether it's usable with AGPL (grrr)
 - Arbitrary RSS Feeds based upon parameters (so we can subscribe to different types or priorities of tickets based on parameters)
   - http://thechaw.com/chaw/feeds/tickets/
   - http://thechaw.com/chaw/feeds/tickets/priority:high
   - http://thechaw.com/chaw/feeds/tickets/priority:high/status:on_hold
 - Updating status/priority/anything from a commit message
   - Proposed syntaxes
     - `[ticket:2/status:on hold/priority:high]`
     - `[ticket:2/status:on hold]`
     - `[2/status:on hold]`
     - `[ticket:2] [status:on hold] [priority:high]`
     - `[ticket:2] [status:on hold/priority:high]`
   - CodebaseHQ merely does status updates, so they can do `[on hold:2]`. Any other implementations of such commit hooks that allow multiple types of updates per commit message for a ticket?
 - Some nice syntax-highlighting by default

## Wiki
 - Option to turn off that weird "Wiki-page can belong to Wiki-page" feature. Not very intuitive IMO. Comments?
 - List of all wiki pages currently in system per project/per installation. Might be subject to Auth conditions
 - Option to change the markup from Markdown to Textile or RST etc.
 - File attachments.
 - RSS feed of changes and latest new pages

## Versions
 - Add arbitrary files to versions (seems to be implemented on the rad-dev.org site...)
 - Automated versions from tags in repository
 - Create a tag/export from repository and make it a version

## Updates/Timeline

CodebaseHQ has a neat feature that is kinda like Twitter. Any activity in the project in any area (Wiki, Tickets, Repository) is summarized and added to the dashboard list. Users can also set a status to update everyone as to what they are currently working on or anything really. Their updates are usually application-wide, not project-specific. Underused feature IMO. Could be integrated into the timeline and set as the default view for a project.

## Time Tracking

Users sometimes like to track the amount of time they've spent on a project or task. CodebaseHQ takes time in minutes (although we could use some jQuery script like http://www.datejs.com/ for Time?) and you can either assign it to a particular ticket (from within the ticket or in the time tracking section), give it a description of a task, or both. Optionally, there is a commit hook that searches for "{TX}" in a commit message, where "X" is the number of minutes spent on the commit. This, combined with ticket updating from commit messages, makes Time Tracking a very powerful and useful tool.

RSS feed per-person/per-project of time tracking

## Calendar

Optionally tag milestones, meeting and due dates, etc here. Useful for project planning. Again, RSS feed anyone?

## Files and Resources

Keep resources attached to a project here. Can also browse all files attached to tickets, maybe a preview function for certain types of files. Slideshow for images maybe?

An image slideshow would be really cool if we could somehow have "folders" for files. These sections could be then assigned to particular groups using access control and then we could invite new contributors (eg. clients) to view particular slides on a project.

Could definitely use an RSS feed.

## User accounts
 - OpenID integration/foaf+ssl/OAuth?
 - Generate foaf profiles for users (not so it can be a foaf+ssl providor, but just because you can). Microformats for everyone!
 - Pick an email to use for gravatars, so multiple email addresses
 - Caching gravatars to mitigate Email-hacking
   - See http://www.developer.it/post/gravatars-why-publishing-your-email-s-hash-is-not-a-good-idea
 - Generate fractal to use in case of non-existing gravatar. CodebaseHQ has a nice implementation of this.
 - Set a custom avatar if user does not want a gravatar account, fractals are not desired, or company wants to do some image branding (See the mustaches from http://www.plankdesign.com/en/about for an idea as to what I mean :P)
 - Maybe a short bio? This might be out of the way of SCM, but its useful so that clients and developers can become familiar with each other without actually meeting. At least it would be a way for me to let others know about our clients and what they personally do without giving them a lecture

## Other ideas
 - Creating plugins based on those in http://trac-hacks.org/ . Could be fun! haha
 - Installation plugin, something like what Croogo (http://croogo.org/) has. Or a self-modifying AppController file (I've done this before :P).
 - Moving installations? A How-to perhaps?
 - Better installation guide. Mitigated if we get an installation plugin or something
 - Better documentation. Not many non-CakePHP or non-Lithium developers are aware of the project itself, so its a pain to contribute as there isn't much documentation as to how it works
   - Corollary: Use github to track thechaw... Ironic? Would allow many more contributors though, and at the end of the day a better product is a better product.
 - Integrated pastebin. Pastium.org has a good example of what an end product should look like. So geshi integration?
 - Analogue! Yet another example of a project that would do well to be integrated with thechaw. Probably best suited as a plugin though...
 - Money generation. In a denomination of the users choice. Would be a useful feature.
