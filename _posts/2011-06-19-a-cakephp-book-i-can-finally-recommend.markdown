---
  title: A CakePHP Book I can finally recommend
  category: CakePHP
  tags:
    - book
    - cakephp
    - application
  description: Review of Mariano Iglesias' CakePHP 1.3 Application Development Cookbook
  comments:    true
  sharing:     true
  published:   true
  layout:      post
---

{% blockquote %}
Note: This post was created a few weeks ago and in my idiocy I forgot to publish it. I blame Jekyll+GIT.
{% endblockquote %}

Since I am in the #cakephp IRC room constantly, I see the question **"What book should I buy to learn CakePHP?"** every so often. It's a painful question, since it sort of means that the documentation that has been contributed is lacking in some way, or that CakePHP is extremely hard to learn. Nevertheless, it's a valid question, and I've asked others similar questions when delving into a new language, framework, or tool-chain.

I recently - read, a week ago - had a chance to read through [CakePHP 1.3 Application Development Cookbook](http://www.packtpub.com/cakephp-1-3-application-development-cookbook/book) by Mariano Iglesias. I've read the other CakePHP books - Golding's was okay, Kai Chan's was terrible IMO - but I hadn't found anything I liked. There are two international books, one from the German Community and one in Japanese, but those have limited utility for obvious reasons. Mariano's book definitely fills a need that many CakePHP developers will have at some point.

The book doesn't go through a large, end-to-end application. You won't see a Wordpress-like application built, nor is this like the Pragmatic Programmers Rails shopping cart. Rather, it focuses on specific needs that a developer will have, whether it be OpenID integration with the `AuthComponent`, datasource creation, or automated shell tasks. Each chapter can be thought of as a cookbook, with multiple recipes, each leading to the next in a logical progression. The breakup of the chapters was well-thought out, and it should be relatively simple for anyone to take bits and pieces from any chapter to construct an application.

A few things stuck out while reading the book and going through examples:

* You should have some knowledge of MVC. The book doesn't do much handholding, which is both good and bad depending on your needs.
* While the code within the book is well-documented, code from GitHub is not. Fair warning if you have needs outside of the plugin's capabilities.
* The book does not have many performance enhancements. If thats what you needed, you shall not find them here.

That said, I did find a few gems. For example, I'd never actually used a custom find as part of a `Model::find('count')`, and had not even considered that as a potential problem, yet here was the solution in plain sight. It did not even require overriding the `Model::find('count')` method, which was quite nice. Another gem was the token-based authorization for building an API, which I ended up using in my own work at a later date. I've already suggested the book to a few developers solely for the extensive chapter on Validation and Behaviors.

One thing that irked was that some of the entries in the book would have been better suited as contributions to the CakePHP core. In particular, adding enhanced Transaction and Locking support to MySQL might have been better suited as a pull request, and his entry could have been the explanation of it's usage. As well, there were examples which completely skipped knowledge gleaned from previous examples; In introducing testing, wrapper methods around `Model::find()` were created, instead of using custom model finds as discussed in previous chapters.

I'm quite pleased with the resulting book though. It's definitely the most up-to-date book, and has knowledge that can be passed doen to **1.2** developers, and much of the ideas are easily transferable to the upcoming **2.0** release. I look forward to implementing a few of the ideas in my own applications, and can honestly say that there is finally a book worth paying for if you're a CakePHP developer.

{% blockquote %}
No, I wasn't paid for this. That would have been rad though.
{% endblockquote %}
