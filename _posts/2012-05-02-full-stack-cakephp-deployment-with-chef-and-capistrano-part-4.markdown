---
  title:       "Creating a cookbook and running chef-solo"
  date:        2012-05-02 01:53
  description: How to create a cookbook for the Chef Deployment Tool and an explanation of DNA.json files
  category:    Opschops
  tags:
    - cakephp
    - chef
    - deployment
  comments:    true
  sharing:     true
  published:   true
  layout:      post
  series:      Full Stack CakePHP Deployment With Chef and Capistrano
---

Now that you've brushed up on how individual pieces of chef work, we're going to create our own chef cookbook and use it within a dna file.

## Chef Cookbooks

As explained in [part 2](/2011/10/26/full-stack-cakephp-deployment-with-chef-capistrano-part-2/), cookbooks can contain lots of bits to make up a single whole. At SeatGeek, we typically have very generic cookbooks along the lines of:

- elasticsearch: Installs the elasticsearch server and client, with recipes for both `0.18.7` and `0.19.3`
- percona: Installs the percona mysql server and client, but also contains some handy definitions for ensuring users are properly created
- php: PHP, PHP with FCGI, a bunch of random modules, and a pear recipe/definition. Pretty handy since PHP is deployed everywhere
- rabbitmq: Rabbitmq, for message passing
- nginx: Customized nginx recipe that installs from source with a few extra modules, with some `nginx_site` definition magic

You get the idea. Generic cookbooks are cool because you can extend them to build different types of servers:

- `bee` instances: instances dedicated to running background processes. They use `percona::client`, `php` with modules, a custom `r` cookbook for our `r` dependencies
- `www` instances: instances that run the live site. `nginx`, `php`, `python` and the `percona::client` are key here.
- `admin` instances: For stuff like logging with logstash and various administrative stuff we use a combination of the `elasticsearch::server`, `nginx`, `php` and `logstash` recipes to get shit done.

Each instance also has SeatGeek specific stuff, so we put that in a `seatgeek` cookbook. Occasionally we have side projects that become large enough to warrant their own repo on github, and I'll typically create a cookbook just for those projects.

- `admin` recipe: Ties together some admin-specific configuration stuff
- `users` recipe: All the devs need deploy access, so we give them access to that user here, as well as give certain devs sudo perms
- `packages` recipe: SeatGeek depends upon certain system packages being installed, so we just do it wholesale within this recipe.

By separating your cookbooks between generic and internal cookbooks, you can much more easily pick and choose from the community, contribute those recipes, and ensure your configuration isn't in 9 million places. Ops is tough enough without having to `awk` through your cookbooks to figure out where you setup master-master replication for MySQL.

## My First Cookbook

I'm going to create a very simple cookbook, whose only job will be to setup users on the server with sudo permissions.

### The deploy user

Each instance has a special `deploy` user, with access to the codebase in a special chroot jail for security. We won't worry about that jail for now, but we do need the `deploy` user. The following would be the beginning of our `users/recipes/default.rb` file:

```ruby
user "deploy" do
  comment "Deploy User"
  home    "/home/deploy"
  shell   "/bin/bash"
  uid     1001
  supports :manage_home => true
  action [ :create, :manage ]
end
```

The above will create a `deploy` user, with a home folder and a bash shell by default. We set our `uid` so that the `uid` for specific users is the same across boxes and we need not worry about permission issues when rsync'ing data. Pretty straightforward, but we need to setup ssh for the deploy user:

```ruby
directory "/home/deploy/.ssh" do
  owner "deploy"
  group "deploy"
  mode 0755
  action :create
  not_if { File.exists? "/home/deploy/.ssh" }
end

# Add deploy private and public key for GitHub
cookbook_file "/home/deploy/.ssh/id_rsa" do
  source "home/deploy/ssh/id_rsa"
  owner "deploy"
  group "deploy"
  mode 0600
  action :create
end

cookbook_file "/home/deploy/.ssh/id_rsa.pub" do
  source "home/deploy/ssh/id_rsa.pub"
  owner "deploy"
  group "deploy"
  mode  0600
  action :create
end

# Set a custom ssh_config for the deploy user so we can ssh
# without having to accept a known_host
template "/home/deploy/.ssh/config" do
  source "home/deploy/ssh/config.erb"
  owner "deploy"
  group "deploy"
  mode 0600
  action :create
end
```

Here, we create the public/private key for Github from the `cookbook_file`s in the path specified. I like to mimic the path the file will be created on within my cookbooks as it makes it easy to figure out where a particular file is generated from when on the instance in question. In this case, we'll have `users/files/home/deploy/ssh/id_rsa` and `users/files/home/deploy/ssh/id_rsa.pub` files. You can guess what is within those files ;)

We also create an ssh `config` file to manage ssh perms. This uses the `users/templates/default/home/deploy/ssh/config.erb` file. The `default` keyword is related to how Chef proposed managing multiple environments at one point, but for legacy reasons has to stick around. I recommend skipping over environments and just sticking to that `default` path, otherwise things get weird. Here is the template file I use in my own open sourced cookbooks:

```ruby
# Autogenerated by Chef for <%= @node[:hostname] %>

Host *
  CheckHostIP yes
  ControlMaster auto
  ControlPath ~/.ssh/master-%r@%h:%p
  SendEnv LANG LC_*
  HashKnownHosts yes
  GSSAPIAuthentication no
  GSSAPIDelegateCredentials no
  RSAAuthentication yes
  PasswordAuthentication yes
  StrictHostKeyChecking no
```

Now we just have to create our users:

```ruby
first_uid   = 1002
deploy_gid  = 1001
ssh_keys    = []

node['users'].each_with_index do |u, i|
  u[:ssh_keys].each {|key| ssh_keys << key }
end

# Create an authorized key for every user we have for deploy
template "/home/deploy/.ssh/authorized_keys" do
  source "home/deploy/ssh/authorized_keys.erb"
  variables(:keys => ssh_keys)
  owner "deploy"
  group "deploy"
  mode 0600
  action :create
end
```

Here we simply collect the user's ssh keys and add them to the deploy user's `authorized_keys` file. The `node['users']` data comes from your dna file, which we will explain in a bit, but here is the gist:

```javascript
"users": [
  {
    "username": "jose",
    "fullname": "Jose Gonzalez",
    "ssh_keys": ["SERPADERP"]
  }
]
```

We also would need that template file in `users/templates/default/home/deploy/ssh/authorized_keys.erb`:

```ruby
<% @keys.each do |key| %>
<%= key %>
<% end %>
```

Lots to learn, but we've just created our first cookbook which will setup the deploy user on our server. You can obviously do more complex things with different available resources, as well as your own custom resources, so I'll leave that as an exercise to you.

One thing to note is that you should strive to ensure that the output of running your cookbook multiple times will not be non-deterministic. That is to say, if I kept running chef on the box with your cookbook, it better not flip-flop on created files, permissions, etc. If we do that, then we can always depend upon the boxes being in a certain state, which eliminates a lot of ridiculousness you'll deal with in the ops world.

## DNA Files

DNA files are how we tell Chef what a server is like. We can specify server attributes, roles to be run, recipes to process, and packages to install. You can specify dna files as `ruby` or `json` files; `ruby` dna files are pre-processed into `json` before being run by chef, so keep them in `json` if you want absolute control on that part of the process.

The following `www-ec2-01.json` file would run our newly minted cookbook:

```javascript
{
  "box_name": "www-ec2-01",
  "run_list": [
    "recipe[users::default]"
  ]
}
```

When specifying a recipe to run, you may omit `::default` if you mean to run the `default` recipe for a particular cookbook. Otherwise, it is required. In our case, the above is identical to the following dna file:

```javascript
{
  "box_name": "www-ec2-01",
  "run_list": [
    "recipe[users]"
  ]
}
```

I normally specify a `box_name` which sets the hostname for the instance in a separate recipe. Please note that this is usually done with `chef-solo`, and running a `chef` server will use another way to identify instances, so please consult that documentation to figure out the server setup.

Running this dna file on the server - chef doesn't run on your machine! - would be done as follows:

```bash
chef-solo -c path/to/chef/solo/config.rb -j path/to/dna/www-ec2-01.json
```

You can specify a config file to give it more options as to where to find recipes etc. Chef runs and gives some output, depending upon it's configured level of verbosity and your recipes.

## Recap

Now that we've successfully run a non-trivial cookbook that actually does something useful - namely allow your developers to deploy to the instance - you're probably thinking that there should be tools to make running `chef-solo` easier. Or what `chef-solo` even is. We'll cover both of those in the next installment in the series, as well as a brief overview of other tools available to you as a chef user.

**To Be Continued**
