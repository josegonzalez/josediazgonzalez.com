---
  title: The Daily Dev Log - 2
  category: Dev Log
  tags:
  description: Always remember to include the host in the protocol when using the EmailComponent
  comments:    true
  sharing:     true
  published:   true
  layout:      post
---

When using the `EmailComponent` in `CakePHP`, the host should always include the protocol. In the case of accessing GMail's smtp support, you may want to use `ssl://smtp.gmail.com` as the host. Just FYI, that will save a ton of time.

[CakeDjjob](https://github.com/josegonzalez/cake_djjob)'s `DeferredEmail` class had a few errors in it, mainly in setting the email addresses for outbound traffic. I had a few of those issues to fix, and was simultaneously wondering whether or not to create a `DeferredEmail` class for `SwiftMailer`. I've decided against it, and that instead I would write an improved `SwiftMailerComponent`, but one using the exact same methods as the `EmailComponent` for setting variables etc. Should be fun, but I don't think I shall be done with it at any point soon.

I discovered an odd bug in some freelance code I wrote a year ago that makes an image that is supposed to be centered just grow until the width of the image is equal to the width of the page. It's a funny problem because it only seems to affect webkit browsers on mobile devices. A quick search reveals no similar issues, so it makes my life that much _easier_ to deal with.
