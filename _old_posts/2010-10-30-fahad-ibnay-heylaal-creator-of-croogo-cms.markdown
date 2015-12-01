---
  title: Fahad Ibnay Heylaal, creator of Croogo CMS
  category:    cakephp
  tags:
    - cakephp
    - croogo
    - cms
    - cakephp 1.3
  description: What does Fahad think about Croogo, CakePHP, and the CakePHP community in general?
  comments:    true
  sharing:     true
  published:   true
  layout:      post
---

I'd like to take a few posts to highlight those non-CakeDC and non-Core developers I feel have done a major service to the community in some fashion. If you fit the bill - I've yet to contact more than a handful of people - feel free to send me a message via twitter, github, email etc.

## What is Croogo?

[Croogo](http://croogo.org/) is an open-source, CakePHP 1.3-based content management system. After about a year of development, it already has quite a following, with [Google Groups](http://groups.google.com/group/croogo), an _extremely_ active [Lighthouse Account](http://croogo.lighthouseapp.com/dashboard), and many, many, many outside developers contributing back to it's core. If you want to liken it to anything, it's the WordPress of CakePHP, without the oddball plugins, weird code snippets, and - necessary - hacks.

## The Interview

1. **The name? Where did that come from?**
    {% blockquote %}The name came from a book in Bengali written by [Muhammed Zafar Iqbal](http://en.wikipedia.org/wiki/Muhammed_Zafar_Iqbal) called Krugo. It was about a robot. I had to read that book a few years ago for a school assignment and used it as the name of the project when I couldn't find anything else to name it. It was his third [science fiction](http://en.wikipedia.org/wiki/Muhammed_Zafar_Iqbal#Science_Fiction). I changed the spelling though, and luckily the domain names were available.{% endblockquote %}
2. **What was the impetus for creating Croogo?**
    {% blockquote %}I was getting very used to coding in CakePHP and liked how it improved my coding skill and made my code more easier to maintain. In fact I began OOP in PHP with this framework. I didn't want to go back to coding PHP the hard way with other popular CMSs, and unfortunately there weren't any CMS based on this framework that I liked then. So I decided to develop one myself, and release it for everyone.{% endblockquote %}
3. **How receptive to Croogo usage have clients been?**
    {% blockquote %}Not many end-users are a fan of the UX Croogo offers, and it is something that will be taken care of in future versions. But most of the clients are OK with it. Luckily I am working with people who give valuable feedback on how to improve it and make it more usable.{% endblockquote %}
4. **How has developing Croogo impacted your personal skill level and amount of client requests?**
    {% blockquote %}Developing Croogo has definitely improved my knowledge on web development, especially with CakePHP. As for client requests, they keep contacting me via my blog for planning/developing/customizing their Croogo based applications. It is really great when you get paid to work with your own software.{% endblockquote %}
5. **What is one thing you would like to rewrite in the existing Croogo codebase?**
    {% blockquote %}I don't think there will be any rewrite in 1.3.x series, and nothing I would like rewritten either. But the Contacts manager, File manager and Attachments could have formed separate plugins themselves. They were developed before the plugin/hook system was introduced in Croogo, so that's OK for now I guess. Will think about that when CakePHP2.0 comes.{% endblockquote %}
6. **You had trouble with developers copying Croogo as their own work. How do you feel about that, and what would you say to other open source developers about this particular topic?**
    {% blockquote %}When you open source your code, you do it because you think someone else will find it useful and build something cool with it. And in that process may be make the code better and contribute it back to the community. But when someone totally steals your code and gives you no credit, it definitely feels bad. But that shouldn't discourage open source developers. In the end, the guy stays alone with the rip-off and the original project continues to grow. You can't steal all the people around an open source project.{% endblockquote %}
7. **Where would you like to see Croogo in 1 year from today?**
    {% blockquote %}Go stable for sure, and may be it will be migrated to CakePHP2.0 by then. It has been only one year this month since its first release. I will just focus on development for now and try to grow a decent community around it over time.{% endblockquote %}
8. **Name one thing that CakePHP could build into the core that would make a product like Croogo infinitely more easy to create.**
    {% blockquote %}Plugins with their own bootstrap and routes. I had to develop something new in Croogo so plugins can have them. But if CakePHP handles this itself, it would be more better and easier I guess. If I am correct, Lithium does something like this for their libraries (plugins).{% endblockquote %}

## Notes

Why in the hell would you use Croogo? As a CakePHP developer, it is always difficult to find the _good_ plugins and applications that exist for usage. I would think that the fact that he is still developing Croogo after a year is a good indicator, and his community, and openness, concerning all matters Croogo should give it a good boost.

I've often thought of the plugin issue, and he is right, it would be nice if plugins could bootstrap themselves. Lithium developers will note that they can perform this - Configure::load() is a good way to perform bootstrapping methods, but routes are a different matter - but CakePHP developers have had to resort to other methods. Perhaps something to petition for/prototype for the upcoming CakePHP 2.0...

Fahad has done a great job fostering his community and I look forward to seeing his contributions to the CakePHP community, and the web development as a whole, in the future. Definitely a developer to look out for.

Download [Croogo](http://croogo.org/) at [Github](http://github.com/croogo/croogo) or track [Fahad](http://fahad19.com/) on [Twitter](http://twitter.com/fahad19).
