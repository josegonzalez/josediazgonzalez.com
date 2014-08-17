---
  title:       "Thoughts - An API for Plugin Installation"
  description: One of my current projects is a CakePHP plugin server. The existing sample was created by John David Anderson of http://www.thoughtglade.com. It is neat and all, and one of the first things I came across when looking at CakePHP 11 months ago.
  category:    CakePHP
  tags:
    - thoughts
    - cakephp
    - plugins
    - side projects
  comments:    true
  sharing:     true
  published:   true
  layout:      post
---

One of my current projects is a CakePHP plugin server. [The existing sample](http://www.thoughtglade.com/posts/plugin-server) was created by John David Anderson of [http://www.thoughtglade.com](http://www.thoughtglade.com/posts/plugin-server). It is neat and all, and one of the first things I came across when looking at CakePHP 11 months ago.

The idea behind a plugin server is simple. There are hundreds of open-source CakePHP code that would be great to use in one's own personal web applications. CakePHP provides Behaviors, Components, Helpers, etc. that will allow one to place this reusable code where needed, but also provides "plugins" that allow users to package up related things into neat little bundles. Sort of like mini-applications. So you could build parts of your applications in plugins, then just bash them together to create websites to a clients specifications with little-to-no work.

Unfortunately, there hasn't been a rash of mini-application releases. I suspect this is because no one cares to release their hard-worked for code, but it doesn't matter. There _has_ been a lot of snippets released, and plenty of components, behaviors, helpers [on the cakephp bakery](http://bakery.cakephp.org), as well as [on thechaw.com](http://thechaw.com), and even [on github](http://github.com). Github's gist feature would go great with this, as it provides a nice way to diff, fork, etc. a file (or package of files) within the browser. If this were integrated with [thechaw.com](http://thechaw.com) and [bakery](http://bakery.cakephp.org) articles, then we'd have a great potential win. Unfortunately, the [recent split of the CakePHP Core Team](http://bakery.cakephp.org/articles/view/the-cake-is-still-rising) between [CakePHP](http://cakephp.org) and [Lithium](http://rad-dev.org/) has me doubting that such a thing would ever happen, as Gwoo, the maintainer of [thechaw.com](http://thechaw.com), went to the Lithium camp. Feel free to contribute to [Bakery 2.0](http://thechaw.com/bakery) and prove me wrong :)

Regardless, it would be nice to have any code that is already plugin-ready to be available to a user via git, hg, svn etc. I personally use git, so I'm going to concentrate on that, although the paradigms are almost all the same across each platform. A project has a url, a main maintainer, some branches, a readme, and perhaps some links. In some cases, a plugin may require another, so just another thing to keep track of. Andy Dawson of CakePHP and Lithium fame actually was working on something of an api for this. You can read his proposal at [http://code.assembla.com/mi/subversion/node/live/1858/branches/mi_plugin/vendors/packages.txt](http://code.assembla.com/mi/subversion/node/live/1858/branches/mi_plugin/vendors/packages.txt).

Anyways, here is what I think. JSON.

```javascript
{
    "id" : "123",
    "slug" : "trackable-behavior",
    "package" : "Trackable Behavior",
    "description" : "Who created or modified this record?"
    "maintainer" : "someemail[a]savant[dot]be",
    "website" : "http://josegonzalez/tracker/cakephp/trackable-behavior",
    "type" : "behavior",
    "dependencies" : "",
    "created" : "2009-08-22 18: 38: 17",
    "modified" : "2009-11-27 03: 44: 32",
    "main-scm" : "git",
    "repository" : "git://josegonzalez.com/cakephp/trackable-behavior.git",
    "other-scm" : {
        "svn" : "http://josediazgonzalez.com/svn/cakephp/trackable"
    },
    "branches" : {
        "main" : "master",
        "1.2" : "1.2-release",
        "1.3" : "1.3-dev",
        "dev" : "experimental"
    }
}
```

Ideally, the plugin would be standalone, both a server and a set of shell scripts. The server would output JSON similar to the above for each record. A user would be able to log onto the site, register a plugin of theirs (with the appropriate links for repository browsing, branches where necessary, dependencies, etc.) and that plugin would be available immediately via a JSON api. Users would also be able to browse the plugin server, check out available plugins, perhaps see screenshots or readme files where appropriate, and more information about the author. Maybe even a download in zip or tar format of the plugin. So something akin to Github, except explicitly for CakePHP code.

The server, upon aggregating the new plugin, would attempt to mirror the plugin for future reference. In the case that a plugin is no longer available at it's original source, the plugin server provider would have the option of mirroring the plugin on their own server, and also replicating it across HG and SVN, or whatever other SCM they intend to implement. If done properly, they could also be made aware of other plugin servers, so in the case that the user cannot find the plugin at the original source nor at the plugin server, a different server can kick in and act as a backup if the plugin is available there. This way, we do not overburden any one server, and we do not force providers to become one-stop shops. It also lets developers forget about how others may want to use their code, so if I am on a team that uses HG exclusively, I do not have to worry about the fact that all the plugins are stored on github and vice versa.

Each SCM library would be implemented via a small PHP class. The class would simply provide definitions for accessing local repositories and serving the correct url for a remote repository. So the class would handle serving and requesting specific branches if necessary. It would also mean that if I were too lazy to implement an SVN (heaven forbid someone is using CVS or even Darcs, *shudder*), then anyone else would be able to do so and thereby extend the core plugin installer. A common library API will need to be settled upon, but it should not be a big deal.

The final thing would be a cake shell that will be able to query this API and install plugins. The basic tasks are as follows

- Search for a plugin
- Install/Remove plugin(s)
- Upload a plugin to a plugin server
- Update all installed plugins
- Configure settings for project/plugin installer

Ideally, one would be able to specify a server from which to grab a plugin. The following is a sample cake shell call:

```bash
cake plugin install -server "http://thechaw.com/plugins" -name trackable-behavior -branch 1.3 -scm git -basepath app/plugins/trackable
```

The above would query [http://thechaw.com/plugins](http://thechaw.com/plugins) for a plugin matching the slug _trackable-behavior_ and, using git, install the _1.3_ branch in _app/plugins/trackable_. Updating *only* the trackable behavior plugin would be a breeze (assuming we cached the installed plugins somewhere, like in a database or something):

```bash
cake plugin update -server "http://thechaw.com/plugins" -name trackable-behavior
```

If you don't like typing out the server, scm, branch, or base install path, one might do the following

```bash
cake plugin configure -server "http://thechaw.com/plugins" -branch 1.3 -scm git -path app/plugins/
```

New plugins would be installed using the 1.3 branch where possible (master in all other cases) from thechaw.com into app/plugins (we would be able to specify a directory name using something like -relpath later).

Of course, the cake shell would request a new list of all plugins at least once a week, or could be configured to refresh it's cache. Would be cool to store all of this in either a cache file, a raw json dump, or even Sqlite (CakePHP _does_ have a datasource for that). I'm still evaluating this, and I should be able to make some incremental progress on at least the server portion soon.

I know I don't have commenting on this blog, but if anyone has any ideas, feel free to send me a message on twitter or github.

_Note: I currently have a plugin installer at [http://github.com/josegonzalez/cakephp-github-plugin-plugin/](http://github.com/josegonzalez/cakephp-github-plugin-plugin/). I'm not even going to go into it's workings on this post. Lets just say it is quite silly. You WILL need git for this to work, but it currently tracks around 80 plugins available on github._
