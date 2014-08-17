---
  title:       "Chef Recipes"
  category:    Opschops
  tags:
    - deployment
    - chef
    - cakephp
  description: What goes in a Chef Recipe, and how much do I really need to know about resources?
  comments:    true
  sharing:     true
  published:   true
  layout:      post
  series:      Full Stack CakePHP Deployment With Chef and Capistrano
---

{% blockquote %}
This text is the second in a long series to correct an extremely disastrous talk at CakeFest 2011. It will also hopefully apply to more than CakePHP.
{% endblockquote %}

## Chef Cookbooks

What is a Cookbook really?

{% blockquote %}
Cookbooks are the fundamental units of distribution in Chef.
{% endblockquote %}

Yes, I had a blank face when I read this as well. A Cookbook can be thought of as a set of bundled files that do a particular task, like install/setup Apache, or install the proper iptables etc. Cookbooks can be thought of as plugins, and can be reused across multiple server setups.

I personally use the [official cookbooks repository](http://community.opscode.com/cookbooks) as a guide to creating my own, custom cookbooks.

Cookbooks have the following:

* [Attributes](http://wiki.opscode.com/display/chef/Attributes): Basically a set of defaults for your recipe. If creating a custom recipe, you can use these defaults as a base and let users override in their `DNA` on a case-by-case basis.
* [Definitions](http://wiki.opscode.com/display/chef/Definitions): Definitions create new Resources. This is an incredibly powerful tool, as a resource is a group of tasks that should be performed in concert, and being able to reference these DRY-ly is the holy grail of server deployment :)
* [Files](http://wiki.opscode.com/display/chef/File+Distribution): Usually config files that need to be copied in to a directory and left alone. `init.d` scripts fit well in this category.
* [Recipes](http://wiki.opscode.com/display/chef/Recipes): Sets of instructions that use up the rest of the cookbook in a programmatic fashion to actually *DO* things. Recipes are the hearts and souls of cookbooks.
* [Templates](http://wiki.opscode.com/display/chef/Templates): Templates allow you to do exactly as you think. Template out files, like apache virtualhosts, by filling out variables set from the Recipe. Pretty easy to use, and even allow some embedded ruby via `erb`

The most interesting of these is the Recipe, for obvious reasons

## A Simple Recipe

The following is a very simple recipe meant to show off a few things in Chef.

```ruby
node[:static_applications].each do |hostname, sites|

  sites.each do |base, info|

    directory "#{node[:server][:production][:dir]}/#{hostname}/#{base}" do
      owner "deploy"
      group "deploy"
      mode "0755"
      recursive true
    end

    git "#{node[:server][:production][:dir]}/#{hostname}/#{base}/public" do
      repository info[:repository]
      user "deploy"
      group "deploy"
    end

    nginx_up "#{node[:nginx][:dir]}/sites-available/#{hostname}.#{base}" do
      hostname "#{base}.#{hostname}"
      variables(info)
    end

  end

end
```

If you'll notice, I'm referencing `node` quite a few times. `node` is a reference to the configuration in your `DNA` file. I normally use `json` files, so `node[:static_applications]` is simply a key in that json file. In this case, I'm iterating over all the `:static_applications` which is a set of hostnames mapping to site configurations. Each one of these is actually a base path mapping to some configuration info as follows:

```javascript
{
  "static_applications": {
    "josediazgonzalez.com": {
      "archives": {
        "repository": "git://github.com/josegonzalez/archives.josediazgonzalez.com.git",
        "subdomain": "archives.",
        "path": ""
      },
      "default": {
        "repository": "git://github.com/josegonzalez/josediazgonzalez.com.git",
        "subdomain": "",
        "path": "/_site"
      }
    },
    "areyousmokingcrack.com": {
      "default": {
        "repository": "git://github.com/josegonzalez/areyousmokingcrack.com.git",
        "subdomain": "",
        "path": ""
      }
    }
  }
}
```

So we iterate over some configuration. Cool. But whats the stuff inside the loops do?

### Built-in Resources

There are quite a few built-in resources in Chef. The ones I use most often are `Directory`, `Git`, and `Template`, and some of these are actually in my example above (not template).

The `Directory` resource merely creates a directory in a desired path with the desired config, such as directory owner and permissions.

The `Git` resource is interesting because it's actually a provider of the `SCM` resource. This means it provides some configuration, and a bit of magic, on top of the `SCM` resource to provide an implementation specific to Git, but that can be moved to, say, `SVN` with minimal work. If you're coming from the CakePHP world, it's akin to how `DboMysql` extends `DboSource` to provide `MySQL` specific interfaces.

The `Template` resource allows you to template out files by passing it variables.

### Back to the Loops

So in my loop, I do the following:

#### Create a directory in the servers production directory for the given static_app

```ruby
directory "#{node[:server][:production][:dir]}/#{hostname}/#{base}" do
  owner "deploy"
  group "deploy"
  mode "0755"
  recursive true
end
```

#### Clone the application from github to the aforementioned directory

```ruby
git "#{node[:server][:production][:dir]}/#{hostname}/#{base}/public" do
  repository info[:repository]
  user "deploy"
  group "deploy"
end
```

#### Use a custom defined Resource to tell nginx to turn on this static_app

```ruby
nginx_up "#{node[:nginx][:dir]}/sites-available/#{hostname}.#{base}" do
  hostname "#{base}.#{hostname}"
  variables(info)
end
```

## Recap

That may have seemed like a lot of information, but it should set the stage for pulling cookbooks together to build cogent deployments. We defined a short recipe, combined a few built-in resources with a custom resource, and configured the whole thing in our `dna.json`. If we had run this, assuming `nginx` and `git` were installed on the server, we would have three static applications deployed on our instance.

Making a recipe isn't very hard, as we found out above, but creating custom resources might seem a bit daunting. We'll go over that, as well as templating and how to best use attributes in the next post.

**To Be Continued**
