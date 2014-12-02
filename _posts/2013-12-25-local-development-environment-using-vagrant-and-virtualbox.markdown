---
  title:       "Local Development Environment using Vagrant and Virtualbox"
  date:        2013-12-25 16:29
  description: "Tired of reinstalling your development environment? We've created one specifically for CakePHP usage."
  category:    CakePHP
  tags:
    - CakeAdvent-2013
    - cakephp
    - development
    - vagrant
  comments:    true
  sharing:     true
  published:   true
  layout:      post
  series:      CakeAdvent-2013
---

One thing developers have issues with is setting up their local development environment. You install a piece of software, it breaks something, and then rolling back is annoying. Or perhaps you have a new laptop, and now you need to reinstall the entire kitchen sink.

I've been using [Vagrant](http://www.vagrantup.com/) for the past few months to great success. Vagrant allows you to automate the creation and lifecycle of a virtual machine. You can *provision* a new machine, automatically run code, and have a fully working environment in a few miinutes. The hard part is figuring out the exact steps needed to get your development environment up to speed.

My Christmas gift to CakePHP developers is the *[FriendsOfCake/vagrant-chef](https://github.com/FriendsOfCake/vagrant-chef)* repository, a vagrant installation custom-built for CakePHP applications. It will automatically setup the following within a virtual machine:

- Ubuntu 12.04 Precise Pangolin
- Ningx 1.1
- PHP 5.5
- Percona MySQL 5.5
- Redis 2.8
- Memcached 1.4
- Git 1.7
- Composer

How do we do it?

1. Install [Vagrant](http://www.vagrantup.com/downloads.html)
2. Install [Virtualbox](https://www.virtualbox.org/wiki/Downloads)
3. `git clone https://github.com/FriendsOfCake/vagrant-chef.git`
4. `cd vagrant-chef`
5. `vagrant up`

Once it's up, you can simply replace your `app` directory with your application and visit `192.168.13.37`. Your application should be ready and raring to go!

For more information, please visit the  *[FriendsOfCake/vagrant-chef](https://github.com/FriendsOfCake/vagrant-chef)* repository! Happy Holidays!
