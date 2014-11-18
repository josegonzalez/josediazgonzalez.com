---
  title:       "Using a personal git host"
  date:        2013-09-09 02:53
  description:
  category:    Opschops
  tags:
    - digital-ocean
    - git
    - gitlab
  comments:    true
  sharing:     true
  published:   true
  layout:      post
---

{% blockquote %}
Shameless Plug: Sign up for <a href="https://www.digitalocean.com/?refcode=fe06b043a083">Digital Ocean</a> using my <a href="https://www.digitalocean.com/?refcode=fe06b043a083">referral link</a> so I can get some money out of this :)
{% endblockquote %}

I recently installed [Gitlab](http://gitlab.org/) on my [Digital Ocean](https://www.digitalocean.com/?refcode=fe06b043a083) account. I did so for a few reasons:

- I've done less freelancing (I'm bad at it) so there was no need for my CodebaseHQ account
- Wanted to host my side-projects that I have been neglecting to version control
- Always liked the idea of managing my own project management tool

Luckily, Digital Ocean [wrote a post](https://www.digitalocean.com/community/articles/how-to-set-up-gitlab-as-your-very-own-private-github-clone) on setting up Gitlab. It's quite straightforward to install<sup>[1]</sup>, and once it was up and running, it was trivial to fall into my normal GitHub usage flow.

I have a tendency to start working on side-projects and never complete them, or sometimes even forget to create a git repository for them. It's very easy for me to fall into this pattern for multiple projects, always thinking to myself that I didn't want others to use it until it was in a working state. I also believed that certain things were private - some side-project where I create the next million dollar idea - and as such neglected basic software engineering principles.

Once I setup Gitlab, I started creating new repositories to hold all my code, good or bad. I have some abandoned side-projects sitting there - monitoring, webapps, cli tools - as well as my current interests.

One thing I noticed was that I had ~19 projects where I had not even bothered to do some/all of the following:

- Add a readme with usage/installation instructions. Not even a vision of how I envisioned the thing would work.
- Use proper dependency management. Oh, you need this ruby gem? Just keep running/installing until you get no bugs!
- Point out where the thing was running, if it was supposed to be online.
- Create a git repository.

These issues definitely had an impact on my work on any project. Without proper documentation, I didn't have a vision for how specific tasks would be implemented, and I certainly would not be able to setup an app on another computer should my current one die. Likewise, as I continued to not use version control on a given project, I would become more and more unlikely to start that process at any point in the future.

Needless to say, I'm quite happy with my current setup. It allows me to continue working on my side-projects and forces me to do all the things I preach about. I'm looking forward to setting up Gitlab-CI integration, which will definitely be a boon to my testing patterns.

{% blockquote %}
Shameless Plug: Sign up for <a href="https://www.digitalocean.com/?refcode=fe06b043a083">Digital Ocean</a> using my <a href="https://www.digitalocean.com/?refcode=fe06b043a083">referral link</a> so I can get some money out of this :)
{% endblockquote %}

[1]: Like they mention, you may need some amount of swap. I was on a 1GB droplet, so I added a gigabyte of swap. All was well after this.
