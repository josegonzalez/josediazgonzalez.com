---
  title: CakePHP Plugins - A Biblical Retelling
  category: CakePHP
  tags:
    - cakephp
    - github
    - plugins
    - useful
  description: A list of CakePHP plugins I use and abuse on a daily basis, as well as things I've discovered but haven't found a use for but seem to be cool.
  comments:    true
  sharing:     true
  published:   true
  layout:      post
---

I'm just going to list a few plugins I use and abuse on a daily basis, as well as things I've discovered but haven't found a use for but seem to be cool. YMMV, but things should mostly work in CakePHP 1.3 unless my description says otherwise.

Any plugin advertised to work in 2.0 should also work in 2.1 just fine.

## Authentication and Authorization:

- [Debuggable's Authsome](https://github.com/felixge/cakephp-authsome): <a href="https://github.com/felixge/cakephp-authsome" class="cake-version version-13">1.3</a> <a href="https://github.com/felixge/cakephp-authsome" class="cake-version version-12">1.2</a> A no-nonsense replacement for AuthComponent. It doesn't handle redirection, just authentication to your app. On the plus side, it has `Authsome::get('fieldName')`, so retrieving logged-in user data anywhere is a breeze.
- [Jose Gonzalez's Sanction](https://github.com/josegonzalez/sanction): <a href="https://github.com/josegonzalez/sanction/tree/2.0" class="cake-version version-20">2.0</a> <a href="https://github.com/josegonzalez/sanction" class="cake-version version-13">1.3</a> Something I cooked up, it works with Authsome and a simple config file to manage your application's permissions. It's cool in that there is a Helper that can be used to replace HtmlHelper and jacks into your Permission configuration file.
- [Nick Baker's Facebook](https://github.com/webtechnick/CakePHP-Facebook-Plugin): <a href="https://github.com/webtechnick/CakePHP-Facebook-Plugin/tree/cakephp2.0" class="cake-version version-20">2.0</a> <a href="https://github.com/webtechnick/CakePHP-Facebook-Plugin" class="cake-version version-13">1.3</a> Facebook integration plugin. It can be used in conjunction with AuthComponent - and maybe Authsome? - to create a fully-functional Facebook authentication section. Neato-burrito, and I hope to use it some day. There is also a demo-site [here](http://facebook.webtechnick.com/).
- [Nick Baker's Gigya](https://github.com/webtechnick/CakePHP-Gigya-Plugin): <a href="https://github.com/webtechnick/CakePHP-Gigya-Plugin" class="cake-version version-13">1.3</a> Looks like a custom social network plugin that integrates with other networks on the service end with one api on your end. Haven't explored it too much, but the idea seems solid.
- [Jedt's Spark Plug](https://github.com/jedt/spark_plug): <a href="https://github.com/jedt/spark_plug" class="cake-version version-13">1.3</a> An awesome-sounding user management and admin section integrating Authsome with a simple ACL implementation. I haven't tried it, but it apparently uses my own Filter component to optionally filter permissions. Promising for sure, and I hope to have screenshots soon.
- [Valerij Bancer's PoundCake Control Panel](http://sourceforge.net/projects/bancer/): <a href="http://sourceforge.net/projects/bancer/" class="cake-version version-13">1.3</a>From the description: "admin panel for users and groups management, dynamic database driven ACL menus generation and management, permissions assignment to users and groups."  Cool
- [Travis Rowland's SuperAuth](https://github.com/Theaxiom/SuperAuth): <a href="https://github.com/Theaxiom/SuperAuth" class="cake-version version-13">1.3</a> I'll smack you if you want to implement Row-level ACL and don't use this. It's complete genius, and other than the missing tests - it's pretty advanced functionality, so I'd like tests - I wholly recommend it.
- [Mark Story's ACL Extras](https://github.com/markstory/acl_extras): <a href="https://github.com/markstory/acl_extras" class="cake-version version-21">2.1</a> <a href="https://github.com/markstory/acl_extras/tree/2.0" class="cake-version version-20">2.0</a> <a href="https://github.com/markstory/acl_extras/tree/1.3" class="cake-version version-13">1.3</a> <a href="https://github.com/markstory/acl_extras/tree/1.0" class="cake-version version-12">1.2</a> Extra stuff for ACL. Use ACL all day? Use this shell and make your life easier.
- [Mark Story's Menu Component](https://github.com/markstory/cakephp_menu_component): <a href="https://github.com/markstory/cakephp_menu_component" class="cake-version version-13">1.3</a> Build ACL-based Menu's for your application. Cool, no?
- [Matt Curry's Static User](https://github.com/mcurry/cakephp_static_user): <a href="https://github.com/mcurry/cakephp_static_user" class="cake-version version-13">1.3</a> <a href="https://github.com/mcurry/cakephp_static_user" class="cake-version version-12">1.2</a> Want to use `Authsome::get('fieldName')` syntax but you have too much AuthComponent code? This is an easy way to do the same, but with `User::get('fieldName')`. Try it out, it's pretty simple to implement.

## Searching and Pagination:

- [CakeDC's Search](https://github.com/CakeDC/Search): <a href="https://github.com/CakeDC/search/tree/2.0" class="cake-version version-20">2.0</a> <a href="https://github.com/CakeDC/search/tree/1.3" class="cake-version version-13">1.3</a> A proper, although slightly advanced, method of filtering paginated data. Written by the CakePHP expert's themselves. Maybe it needs more tests? ;)
- [Neil Crooke's Filter](https://github.com/neilcrookes/filter): <a href="https://github.com/neilcrookes/filter" class="cake-version version-13">1.3</a> Haven't used it yet, but if it's anything like his Searchable plugin, it blows me out of the water. Meh.
- [Neil Crooke's Searchable](https://github.com/neilcrookes/searchable): <a href="https://github.com/neilcrookes/searchable" class="cake-version version-13">1.3</a> Uses JSON to index searchable records. Pretty awesome, and I've used it on a couple sites, including CakePackages. Definitely something to look into.
- [Matt Curry's Pagination Recall](https://github.com/mcurry/pagination_recall): <a href="https://github.com/mcurry/pagination_recall" class="cake-version version-13">1.3</a> An undocumented plugin that allows one to save the current paginated page to the Session, which can then be retrieved whenever redirecting to the pagination action of that controller. Nifty, and something people ask for all the time.

## File Uploading:

- [Jose Gonzalez's Upload](https://github.com/josegonzalez/upload): <a href="https://github.com/josegonzalez/upload/tree/2.0" class="cake-version version-20">2.0</a> <a href="https://github.com/josegonzalez/upload" class="cake-version version-13">1.3</a> I made an Upload plugin based on my work with MeioUpload and UploadPack. I haven't used it yet, but it's currently ~44% unit tested and once it is at 100%, I'll try it out and let you know ;)
- [Vinicius Mendes' MeioUpload](https://github.com/jrbasso/MeioUpload): <a href="https://github.com/jrbasso/MeioUpload" class="cake-version version-20">2.0</a> <a href="https://github.com/jrbasso/MeioUpload/tree/3.0" class="cake-version version-13">1.3</a> I've worked on this. The versioning is pretty silly atm, but I still say it's definitely usable.
- [Michał Szajbe's UploadPack](https://github.com/szajbus/uploadpack): <a href="https://github.com/szajbus/uploadpack" class="cake-version version-20">2.0</a> <a href="https://github.com/szajbus/uploadpack/tree/ee60f66fe7e09ad313fddd9c9ca168ea744c92aa" class="cake-version version-13">1.3</a> File Uploading with a Helper to output the stuff for you. It's dope, for damn sure. I actually prefer this over MeioUpload now, and I contribute to both and have been the "Maintainer" of both in some fashion over the past year.
- [David Perrson's Media](https://github.com/davidpersson/media): <a href="https://github.com/davidpersson/media" class="cake-version version-13">1.3</a> The grand-daddy of all CakePHP upload plugins. If this plugin doesn't do what you need it to do, the code hasn't been released as a CakePHP plugin. For advanced users only, but you won't be disappointed.

## Optimization

- [Frank de Graaf's Lazy Model](https://github.com/Phally/lazy_model): <a href="https://github.com/Phally/lazy_model" class="cake-version version-13">1.3</a> <a href="https://github.com/Phally/lazy_model" class="cake-version version-12">1.2</a> Make your model chain-loading lazy, and potentially speed up the enormous app you've been building. Definitely something to look into if you are in 1.2/1.3. CakePHP 2.0 will have this in the core, but since that's not out, Lazy Model is the next best thing.
- [Rafael Bandeiras' Linkable](https://github.com/Terr/linkable): <a href="https://github.com/Terr/linkable" class="cake-version version-13">1.3</a> Think of it as Containable Behavior's crazy best friend. You know, the one that is going to rule the world someday, but is busy in his basement writing SQL at the moment. Terr seems to have an updated version of it, so thats what I am linking to. Check it out.
- [Mark Story's Asset Compress](https://github.com/markstory/asset_compress): <a href="https://github.com/markstory/asset_compress" class="cake-version version-20">2.0</a> <a href="https://github.com/markstory/asset_compress/tree/1.3" class="cake-version version-13">1.3</a> Compress your CSS and JS. This plugin rules, and no one other than the current lead developer of CakePHP could have such a gem chilling in his github profile.
- [Matt Curry's HTML Cache](https://github.com/mcurry/html_cache): <a href="https://github.com/mcurry/html_cache" class="cake-version version-13">1.3</a> Cache your pages to HTML. See a huge speedup. Great for static pages. Also has a Croogo hook, if you happen to be using Croogo CMS.
- [Matt Curry's URL Cache](https://github.com/mcurry/url_cache): <a href="https://github.com/mcurry/url_cache" class="cake-version version-13">1.3</a> This snarky guy seems to have gems all over his Github profile. Cache your generated html urls to whatever caching system you use. Greatly speeds up requests on pages with a fuck-ton of URLs to generate.
- [Matt Curry's Custom Find Types](https://github.com/mcurry/find): <a href="https://github.com/mcurry/find" class="cake-version version-13">1.3</a> Definitely an easy way to build custom find types for your application, and easily customizable to add stuff like Caching or Filtering. DO NOT USE IF YOU WANT REAL CUSTOM FINDS, THIS IS A HACK AND IT WILL BURN DOWN YOUR KITCHEN. [USE THIS INSTEAD](https://github.com/josegonzalez/documentation/blob/master/03-good-cake/01-models.textile)

## Debugging

- [Mark Story's DebugKit](https://github.com/cakephp/debug_kit): <a href="https://github.com/cakephp/debug_kit" class="cake-version version-21">2.1</a> <a href="https://github.com/cakephp/debug_kit/tree/0b21dae47edef4a17d41f74fa72d2ed9c734b7c4" class="cake-version version-20">2.0</a> <a href="https://github.com/cakephp/debug_kit/tree/1.3" class="cake-version version-13">1.3</a> <a href="https://github.com/cakephp/debug_kit/tree/1.2" class="cake-version version-12">1.2</a> Honestly, this man is a monster. Not only is he a JS-Ninja and CakePHP-bashing fiend, but he also draws incessantly and has time to hack on the most wonderful tool for debugging your CakePHP application. This is something you need to install NOW. You will love me later.
- [Joe Beeson's Referee](https://github.com/joebeeson/referee): <a href="https://github.com/joebeeson/referee" class="cake-version version-13">1.3</a> "A CakePHP 1.3+ plugin for catching errors and exceptions and logging them." I think that's pretty cool, and so should you.
- [Matt Curry's Interactive](https://github.com/mcurry/interactive): <a href="https://github.com/mcurry/interactive" class="cake-version version-13">1.3</a> A panel for DebugKit to interact with your app without refreshing the page. A great way to see what a particular query will perform.

## Shells

- [Jose Gonzalez's CakeDjjob](https://github.com/josegonzalez/cake_djjob): <a href="https://github.com/josegonzalez/cake_djjob/tree/2.0" class="cake-version version-20">2.0</a> <a href="https://github.com/josegonzalez/cake_djjob" class="cake-version version-13">1.3</a> A wrapper around a port of delayed_job to PHP. Pretty dope, and works well with your existing database
- [Mike Smullin's Reque Plugin](https://github.com/mikesmullin/CakePHP-PHP-Resque-Plugin): <a href="https://github.com/mikesmullin/CakePHP-PHP-Resque-Plugin" class="cake-version version-13">1.3</a> Delayed jobs on the server persisting via Redis is cool too.
- [Pettey Gordon's code_check](https://github.com/petteyg/code_check): <a href="https://github.com/petteyg/code_check" class="cake-version version-20">2.0</a> <a href="https://github.com/petteyg/code_check/tree/1.x" class="cake-version version-13">1.3</a> Verify that your codebase follows CakePHP standards and correct it on the fly. I use it on any existing codebases that come my way.
- [Marc Ypes' clear_cache](https://github.com/ceeram/clear_cache): <a href="https://github.com/ceeram/clear_cache" class="cake-version version-20">2.0</a> <a href="https://github.com/ceeram/clear_cache/tree/1.3" class="cake-version version-13">1.3</a> A lib that will aggressively clear your cache. Can be used pretty much anywhere

## Useful Helpers

- [Graham Weldon's Goodies plugn](https://github.com/predominant/goodies): <a href="https://github.com/predominant/goodies" class="cake-version version-20">2.0</a> <a href="https://github.com/predominant/goodies/tree/1.3" class="cake-version version-13">1.3</a> Contains helpers for Gravatar inclusion, automatic javascript file inclusion within your layout and more.
- [Chris Your's CakeHelper](http://snipt.net/chrisyour/cakephp-content_for-capture-html-block-for-layout/): <a href="http://snipt.net/chrisyour/cakephp-content_for-capture-html-block-for-layout/" class="cake-version version-13">1.3</a> "Ever wanted a clean way to capture a block of HTML in your CakePHP view and use it later in your layout just like CakePHP uses $content_for_layout?" This helper is an implementation of Rails' content_for in CakePHP. Chawsome.
- [Joe Beeson's Analogue Helper](https://github.com/joebeeson/analogue): <a href="https://github.com/joebeeson/analogue" class="cake-version version-13">1.3</a> Sometimes you just need your helpers to pretend to be other, core helpers. Why? How the hell would I know! But now you can!

## Random Awesome-sauce

- [Carl Sutton's Google Plugin](https://github.com/dogmatic69/cakephp_google_plugin): <a href="https://github.com/dogmatic69/cakephp_google_plugin" class="cake-version version-13">1.3</a> Someone give this guy an award. Just a metric fuck-ton of Google Integration into CakePHP. You are all welcome.
- [Joe Beeson's Sassy](https://github.com/joebeeson/sassy): <a href="https://github.com/joebeeson/sassy" class="cake-version version-13">1.3</a> Admit it, you love SASS. Joe rules and built this sick plugin (and released it for you bastards) that integrates SASS into CakePHP.
- [Jose Diaz-Gonzalez's CakeAdmin](https://github.com/josegonzalez/cake_admin): <a href="https://github.com/josegonzalez/cake_admin" class="cake-version version-13">1.3</a> Quickly build an admin dashboard for your entire app based on a single class per model. Looks pretty too.
- [Miles Johnson's CakeForum](https://github.com/milesj/cake-forum): <a href="https://github.com/milesj/cake-forum" class="cake-version version-20">2.0</a> <a href="https://github.com/milesj/cake-forum/tree/2.x" class="cake-version version-13">1.3</a> Likely the best CakePHP forum, and the only one I'd trust to start with. Heavily updated too.
- [Neil Crookes' Blog Plugin](https://github.com/neilcrookes/CakePHP-Blog-Plugin): <a href="https://github.com/neilcrookes/CakePHP-Blog-Plugin" class="cake-version version-13">1.3</a> The be-all, end-all blog plugin. Give it a whirl, you won't be  let down. 2.0+ only.

<style>
.cake-version {
  border-radius: 2px;
  display: inline-block;
  font-family: Helvetica, arial, freesans, clean, sans-serif;
  font-size: 11px;
  font-weight: bold;
  padding: 2px 4px 0px 4px;
  margin-right: 2px;
  text-decoration: none;
}
.cake-version.version-21 {
  background-color: #0951AF;
}
.cake-version.version-20 {
  background-color: #0F3957;
}
.cake-version.version-13 {
  background-color: #FB6C6C;
}
.cake-version.version-12 {
  background-color: #DDDEC6;
  color: #000;
}
a.cake-version {
  color: #fff;
}
</style>
