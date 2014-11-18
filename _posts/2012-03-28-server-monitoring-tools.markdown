---
  title:       Server Monitoring Tools
  category:    Opschops
  tags:
    - deployment
    - monitoring
    - tools
  description: An easy to install, maintain, and use tool for server monitoring doesn't exist, why is that?
  comments:    true
  sharing:     true
  published:   true
  layout:      post
---

I've been recently doing a bit of systems administration at SeatGeek, and it strikes me that much of the monitoring/alerting code there sucks for one or more of the following reasons:

- Ridiculous setup
- Costs money
- Is a service
- Terrible UI
- Terrible Codebase
- Requires a specific version of a library that I cannot get installed on a machine

Here, let me show you them:

## Existing Tools

### Cacti

Cacti is cool. It's supposed to be a real simple way of aggregating statistics about your installations. It uses RRDTool to store data - which is apparently super compressed and efficient at making graphs - with a periodic cron triggered to collect said data. It sucks for the following reasons:

- Codebase was written before they discovered programming patterns. Or actual programming. I honest to god don't know how they continue to fix bugs, it seems so error prone. I think the developers like spaghetti
- RRDTool `.rrd` files must be converted when used on other architectures, like 64-bit => 32-bit. Or Linux => Mac. Kind of annoying to debug the code if you have to convert a crap-ton of files to `.xml` and then back.
- No api to automate adding new services/nodes to Cacti. Bringing up a new webserver means re-adding like 30 items to cacti. You're fucked if this is a new backup machine
- Collecting new stats means writing all sorts of XML files. On top of the stats collection. Guess which one is the bigger pain in the ass.
- Can no longer easily upgrade from non-plugin architecture to the plugin architecture. Which means I can't use Thold for alerts.
- Plugins are out of date, or unmaintained.
- Docs are obtuse.

You get the picture. It's a cool tool, and I totally respect what the folks behind Cacti are doing, but it's definitely not a tool I want to use going forward.

### Nagios

Nagios is supposed to be enterprise. Super-duper enterprise. In fact, it's so enterprise that:

- There doesn't seem to be a straightforward way of installing it. Or at least the 90-million "Install Nagios in 10 easy payments of your soul" don't make it so
- Setting up new items to monitor seems... also not-straightforward. Why do you need a DSL for this? Aren't there UIs/APIs?
- They also sell a paid version. Great, now I know the version I have is not as awesome.

I'd love for someone to prove me wrong, but I have a limited amount of time in the week to implement this stuff.

### Ganglia

Looks like a glorified Cacti. Without something to grab stats. Woot.

### All Paid Services

- I hate paying over nine thousand dollars to get/store useful metrics.
- If your service gets bought, then I'm SOL if I cannot pay whatever the new rate will be
- Featureset/UI out of my control. Usually not a big deal, except when there is a small bug I can fix in 5 seconds/4 lines of javascript but can't because I don't have commit access
- If your repository for installing your code goes away, that breaks my chef cookbooks. Awesome.

## What I'd like

Ideally the tool is easy to install and doesn't require a specific version of a language/library. This rules out `Python`/`Ruby` tools because they will either be built specifically for Ruby `1.8.7` or `1.9.2`, and my machine is not running that. As much as I'd love to use them, they are out simply because of deployment issues.

That leaves PHP.

Preferably not spaghetti PHP. So something built in a framework.

I already have a system for storing data: [Graphite](http://graphite.wikidot.com/) and [StatsD](https://github.com/seatgeek/statsd_rb). I already have the application tossing data at Graphite, but I also have existing Cacti data. What would be nice is a tool to migrate from an existing set of `.rrd` files to Graphite. I can back-date data in Graphite, so this should hopefully be straightforward. The data keys can be:

```generic
hostname.service_name.metric
```

Grouping metrics is key. Because Graphite already stores application-related statistics, and also would store stats on a per-instance basis, I would like a way to track different sets of metrics somewhere. Because of how graphs are created, it would be useful to store information about each graph - who created the graph, usecase, a damned name - along with it. This data could change from graph to graph of course.

Whenever I create a graph, it should be easy to share it with others. My boss may want to see how deploys affect conversions, or we may want to place one of these in a blog post about earthquakes. Sharing the url to a graph should be straightforward. It should also be possible for me to save a snapshot of a graph somewhere, although this can be a generic interface that can be extended as time goes on. Please note, we should be able to annotate the hell out of these stored graphs.

Replacing Cacti is a big reason for building this tool, so it would be useful to build a simple interface wherein I can easily collect stats about different instances and shove them into graphite. It's not easy to figure out what is available for graphing in Cacti, so exploring the Graphite stats tree is an important feature, although not front and center.

Alerts are important. How do we build alerts? You can retrieve raw data from graphite and somehow build some simple trending. Might be too much work for an initial build.

As far as the UI is concerned, [Twitter Bootstrap](http://twitter.github.com/bootstrap/) is cool. All it needs are some changes to the default color scheme to provide a bit of visual identity. Would be dope to be able to specify a logo so that your boss thinks you built some rad tool.

So I want a system built on top of this. In an MVC framework. CakePHP/Lithium preferred, as that is what I am used to, but so long as it isn't terrible code, I don't care. The portions that control graph-creation from graphite should be separate from stats collection. Ideally someone could reimplement the app in their own PHP framework, still using whatever UI/PHP libraries I have with minimal changes.

A recap?

- PHP-based tool, built in a framework
- Graphs should be easy to create, annotate and share. Bonus for embeddable graphs
- Must also collect stats about instances
  - Should be generic enough that it would be possible to write a one-liner to collect a new statistic
- Alerts are useful, but perhaps it would be better to leave alerts elsewhere.
- Some attention should be paid to UI. This is 2012, lets make graphing easy on the eyes
- Graphing/UI should be fairly generic, and easy to move to another framework as necessary


## Some thoughts

I don't have any goals for introducing logs into this. Would be nice to be able to overlay a graph onto a series of logs from instances.

Feels like I would be rebuilding tools that exist. Or that the tools I'm comparing this theoretical system to are vastly different.

Alerts are hard. Is there any easy way to do this with Graphite?

Can this be built from existing tools quickly? Does this exist already somewhere?
