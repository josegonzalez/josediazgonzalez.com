---
  title:       "Creating a CakePHP skeleton"
  date:        2015-12-26 12:00
  description: "A list of things I need in a base application before starting a new cakephp project"
  category:    cakephp
  tags:
    - cakephp
    - scaffold
    - composer
    - planning
  comments:    true
  sharing:     true
  published:   true
  layout:      post
  series:      Media Manager
---

![File Upload Tool](/images/2015/12/26/screenshot.png)

## "I've got a lot of problems with you people"

A while back [^1], I <s>stole</s> built a [simple image upload tool](https://devcenter.heroku.com/articles/paperclip-s3) for our [marketing team](https://seatgeek.com/sgteam). The reason I built this was simple; I wanted to stop the marketing team from uploading large file assets to the main repository [^2], thereby bloating repository size. Plus they get their assets out as soon as they need them, instead of waiting for some silly dev to press the deploy button. It's worked well enough, but has lately shown it's age:

- Thumbnails are processed in a web request, slowing down large file uploads. We should *always* process any files in the background, to avoid slowing down the user's interaction with the site.
- Thumbnails are created *regardless* of the file type. Uploading a large gif? Yeah that won't work.
- Images are uploaded through rails. Since we store assets on S3, we can just as easily upload direct to S3 in javascript.
- I never built in any categorization, tagging, or user functionality. There isn't any way for the marketing team to know who uploaded what file, nor for what purpose.
- A "file" can actually be several different assets. For instance, we frequently resize assets manually - on the client-side at the moment - for use in different media, like ads, email, or on-site ads. Having several different "uploads" made it slightly difficult to see which one someone should use for a specific purpose.
- It doesn't have an API, meaning other teams that might want to use it to store information - such as the Android team - can't easily write an integration like, say, [CloudApp](https://www.getcloudapp.com/) [^3] but just for our internal tool.
- The site is built on an older version of rails [^4], which I have no desire nor intention to upgrade. We also don't really have a dedicated Rails developer, so it's not like I can just toss the app at someone else. We *do*, however, have two CakePHP Core developers on staff, so at worst I can just tell [Andy](https://github.com/ad7six) it's his problem now.

## Let's try and get past this

So I'm building this new app and decided I needed a good base:

- Must have all my favorite plugins - [Crud](/2015/12/02/creating-apis-using-the-crud-plugin/), [Crud View](/2015/12/03/generating-administrative-panels-with-crud-view/), [Upload](/2015/12/05/uploading-files-and-images/), etc. - enabled by default.
- Should handle [error tracking](/2015/12/07/error-handling-in-cakephp-3/) and [logging](/2015/12/14/custom-logging-engines-and-adding-contextual-data/) in a sane way.
- Must be able to handle being [deployed](/2015/12/12/using-dns-to-simplify-connection-strings/) to [heroku](/2015/12/18/managing-application-configuration/) by default.
- Needs support for *some* method of [background queueing](/2015/12/20/creating-custom-background-shells/).
- Should be open source [^5].

Thankfully, we can use composer to [customize our application skeleton](/2015/12/09/customizing-your-app-template/). This will enable me to scaffold out my application more more quickly than I would be able to if I used the base [cakephp/app](https://github.com/cakephp/app) composer project template.

Here is my first pass, [josegonzalez/app](https://github.com/josegonzalez/app). It's based upon the original [cakephp/app](https://github.com/cakephp/app) project template, with many of my requirements fulfilled. Ideally everything would be done now, but that won't ever be the case:

- Still need to add a custom `config/functions.php` for utility functions I tend to use such as `diebug()`.
- I don't *yet* have a contextual logger in place. I'm considering switching to monolog and having all logging go to `stdout` when using the [built-in cake server shell](/2015/12/17/cakephp-shells-i-didnt-know-about/), but I'm not quite sure yet.
- I can't yet *seed* an environment in [dotenv](/2015/12/18/managing-application-configuration/), so heroku support isn't quite complete, but I'm working on it.
- There are quite a few plugins that would be useful to have - such as [muffin/footprint](https://github.com/usemuffin/footprint) - but they aren't there yet. I'll add them as I see general use across my application.

> Side note: I wrote *way* too many blog posts. Do you see the internal linkage up there? Incredible.

## What's next?

Now that I have a firm base for my application, I'll need to start actually building the thing. I'm hoping there isn't too much work, but these things tend to take forever, so we'll see. Since I have a pretty small set of requirements, actually writing the code should be a straightforward process, but hopefully I can do this in a readable, re-usable way.

Be sure to follow along via twitter on [@savant](https://twitter.com/savant). If you'd like to subscribe to this blog, you may follow the [rss feed here](/atom.xml). Also, all posts in the series will be conveniently linked on the sidebar of every post in the Media Manager series. Until next post, meow!

---

[^1]: November 12, 2013 to be precise.

[^2]: Our development staff is no better - and in fact worse as they should know better. Pesky devs, if only I had a good alternative for them...

[^3]: By the way, CloudApp is great. Our entire company uses it and I don't understand why anyone wouldn't. They even have a free tier, which is great of those times when I totally forget to renew my account...

[^4]: It's Rails 3.2.13. I can feel the vulnerabilities pulsating through me.

[^5]: Preferably on my own [github profile](https://github.com/josegonzalez), though I can see this being on our company's profile as well. *shrug* as long as it's out there.
