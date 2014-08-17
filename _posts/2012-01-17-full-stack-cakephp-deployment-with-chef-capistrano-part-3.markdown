---
  title:       "Templates, Attributes, Resources, and Dependency Management"
  category:    Opschops
  tags:
    - deployment
    - chef
    - cakephp
  description: Templating, Custom Resources, and Cookbook creation for the Chef Deployment Tool
  comments:    true
  sharing:     true
  published:   true
  layout:      post
  series:      Full Stack CakePHP Deployment With Chef and Capistrano
---

{% blockquote %}
This text is the third in a long series to correct an extremely disastrous talk at CakeFest 2011. It will also hopefully apply to more than CakePHP.
{% endblockquote %}

## Templates

Templating in Chef is much like templating in any other framework. Chef templates use ERB - eRuby - which is a templating system that embeds Ruby into a document. If you know any Ruby, this should be a fairly trivial thing to learn. For CakePHP developers, think `ctp` files :)

For PHP developers, the big difference is that it uses short-syntax - `<? ?>` - and the question marks are replaced with percent signs - `<% %>`. Along with the short syntax, there isn't an `echo` statement, so if you want to `echo` a variable, `<%= var %>` will do it.

Another key change is in variable output within strings. In PHP, we can do:

```php
    $foo = 'bar';
    $baz = "{$foo}";
    echo $baz; // outputs: bar
```

In Ruby, we might do the following:

```ruby
    foo = 'bar'
    baz = "#{foo}"
    puts baz # outputs: bar
```

That's pretty neat I think, not that big of a change.

Templates alone aren't very useful, but they are normally used in conjunction with the `Template` resource in Chef as follows:

```ruby
template "/path/to/where/template/should/be/written/to" do
  source "some_template.erb"
  owner "root"
  group "root"
  mode 0644
  variables(
    :var_name   => "value"
    :an_array   => [ "of", "values" ]
  )
end
```

In the above example, we are creating the file `/path/to/where/template/should/be/written/to` from the `some_template.erb` file. We're also setting the owner, group and the permissions of the file. The variables `var_name` and `an_array` would be available as variables in the view.

Pretty straight-forward I think.

## Attributes

Attributes are fairly straight-forward. They allow you to set defaults for a particular cookbook by setting/modifying the variables in your `DNA` config.

```ruby
# Deploy settings
default[:server][:production][:dir] = "/apps/production"
default[:server][:production][:hostname] = "example.com"
default[:server][:staging][:dir] = "/apps/staging"
default[:server][:staging][:hostname] = "example.net"

if node.nginx.attribute?("varnish")
  # ... do stuff on NGINX varnish stuff
end

override[:server][:extensions][:gzip] = true
```

In the above, we are setting the default `paths` and `hostnames` for the `production` and `staging` server environments, as well as setting some `varnish`-related configuration if `node[:nginx][:varnish]` exists; We also override the configured server extensions to ensure `gzip` will always be turned on, in case someone tries to turn it off via the `DNA` configuration.

I normally just set defaults and forget about it. For those deploying across multiple Operating Systems, we can do the following to set variables depending upon the OS:

```ruby
# Platform specific settings
case platform
when "redhat","centos","fedora","suse"
  # Some settings here
when "debian","ubuntu"
  # Debian-related configuration
when "windows"
  # Windows-specific defaults
else
  # When all else fails...
end
```

Attributes are a good way of providing simple, cross-platform compatible defaults that can be later tweaked by way of `DNA` files. They allow you to provide a baseline configuration that might be modified in cases where we have more memory, lower disk throughput, or some other deviation from the norm.

If you find that you're constantly setting the same settings in your `DNA` file, feel free to modify the defaults to keep your setups DRY.

## Custom Resources

We're going to fake out Custom Resources because the real way is a definite PITA. You can read about it in the Chef docs if you want.

Definitions are the <del>poor</del> smart mans way of creating resources. Definitions are cool because you can import them across projects, and are very simple to understand by all. I would create a definition when you have a large amount of code you are executing multiple times, maybe in a loop, that really only varies by two or three variables.

A good candidate is bringing up a new virtualhost for nginx.

```ruby
# Definition
define :nginx_up, :enable => true do

  name = "#{node[:nginx][:dir]}/sites-available/#{params[:name]}"

  template name do
    source "html.erb"
    owner "deploy"
    group "deploy"
    mode 0644
    variables(params[:variables])
  end

  nginx_site params[:hostname] do
    action :enable
  end
end
```

The above definition creates a templated virtualhost file and then enables it using nginx. While it is simple, it only displays a small portion of what you can do with definitions. You could simply bring up a virtualhost, or automatically create EBS-mounted volumes with 2 partitions, each having certain folders. That's merely up to your imagination. Personally, I like the beauty of typing the following into my cookbooks:

```ruby
# info is an array of data

nginx_up "#{info[:hostname]}.#{info[:base]}" do
  hostname "#{info[:hostname]}.#{info[:base]}"
  variables(info[:variables])
end
```

Instead of the alternative. But thats just me.

## Dependency Management

This one is simple. Sometimes you need to have another cookbook loaded for your current cookbook/recipe to work. For example, CakePHP applications depend upon `php` being installed, and thus they depend upon the `php` recipe.

We can specify that an entire cookbook depends upon another cookbook (or recipe) in the metadata file (json or ruby, I prefer ruby):

```ruby
maintainer        "Jose Diaz-Gonzalez"
maintainer_email  "support@savant.be"
license           "MIT"
description       "Installs and maintains php and php modules"

depends           "nginx"
depends           "mysql::client"
```

If we conditionally need it for a particular recipe/definition, we just include the recipe as follows:

```ruby
define :pear_module, :module => nil, :enable => true do

  include_recipe "php::pear"

  if params[:enable]
    execute "/usr/bin/pear install -a #{params[:module]}" do
      only_if "/bin/sh -c '! /usr/bin/pear info #{params[:module]} 2>&1 1>/dev/null"
    end
  end

end
```

By default, `php` maps to `php::default`, where `default.rb` is the `default` recipe for a cookbook. Please keep this in mind.

## Cookbook Creation

Cookbooks are an amalgamation of recipes, definitions, templates, files etc. You should always have a `metadata.rb` or `metadata.json` file, which contains metadata about the file. If it is a complicated cookbook, feel free to include a `README` as well, in your preferred markup language (`markdown` is winning, fyi). You'll also have one of several other filetypes, usually a recipe and a template, although they are all optional.

Once you've put together a template, it's usually quite easy to integrate it with your other cookbooks. Just name the cookbook `lower_under_score` and shove it in your `cookbooks` directory. If you are feeling especially helpful, you can also upload it to the [Opscore Community Site](http://community.opscode.com/). Please run your cookbook before sharing, and also clearly state what other cookbooks they depend upon.

One last consideration is to make sure as much of your cookbook is configurable as possible, but with sane defaults. In this way, you'll please the most users, while also encouraging "best" practices.

## Recap

We now have a pretty awesome `nginx_up` resource that can be used across multiple cookbooks. We could go further and make an abstracted `server_up` resource, but I'm pretty happy with our progress for now.

So what's next? Well, we have yet to deploy an entire server, and there is still the matter of what a `DNA` file actually is. As well, it would be useful to know how to actually push all of these files onto the server, and maintain the server as we move ahead. So the next post will cover the following:

- Create a full-fledged cookbook
- `DNA` files, how do they work?

We'll get to the rest at a later date.

**To Be Continued**
