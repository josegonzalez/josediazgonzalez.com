---
  title:       "Deploying your infrastructure to AWS"
  date:        2013-10-17 00:29
  description: "Deployment of servers to the AWS EC2 service, with particular care taken to ameliorate some issues with deploying applications over datastores"
  category:    Opschops
  tags:
    - aws
    - chef
    - heroku
    - provisioning
  comments:    true
  sharing:     true
  published:   true
  layout:      post
  series:      Insane Server Management
---

This document refers to the deployment of servers to the AWS EC2 service, with particular care taken to ameliorate some issues with deploying applications over datastores.

> This is the result of about 6 hours of rambling thought and a few diagrams, as well as 2+ years of fiddling with servers and seeing what definitely does not work. That is to say, there is no guarantee any of the following is `[truthful, working, awesome]`.

## Important

With respect to datastores, it is easier to consider them attached services, and thus not manage them in this setup. The following are recommendations re: datastores:

- RDS for SQL-based applications. It has many desirable qualities, including snapshots, automatic replication, automated failover, easy version upgrades.
- Redshift for large-scale analytics. This can be useful for ie. user-level tracking, or computation across large amounts of data. Please research this before using it, as it may not apply to your case!
- ElastiCache for inter-service caching eases the pain for many (*most?*) applications. It provides an interface to both Memcached and Redis, with similar features to RDS in terms of datastorage management.

Not having used CloudSearch, I cannot recommend it. The same for SQS - though I've been told it is quite expensive for some workloads.

If you:

- desire total control over the care and maintenance of your data
- have a special use-case that wouldn't be covered
- cannot afford the potentially large overhead of your usage

then feel free to manage your own datastores. Again, the notes below may not wholly apply to you, **YMMV**.

## Requirements

- All nodes generated from a single file
- Should generate base packer images
- Should be able to specify a node as a packer group
- Should notify a central system of it's existence
- Should query central system for reconfiguration based on dependencies of other systems
- Should integrate with autoscale groups (optional)

## Node Configuration

Note that we use json here arbitrarily. Implementation is not yet set in stone.

```javascript
{
  "__base__": {
    "autoscale": false,
    "type": "amazon-ebs",
    "region": "us-east-1",
    "instance_type": "m1.large",
    "source_ami": "ami-1ebb2077",
    "security_groups": ["external", "internal"],
    "default_attributes": {
      "environment": "production",
      "key": "value"
    },
    "run_list": [
      "recipe[seatgeek::base-server]",
      "recipe[seatgeek::collect-services]",
      "recipe[seatgeek::decommission-services]"
    ],
    "post_run_list": [
      "recipe[seatgeek::notify-services]",
      "recipe[sudo]"
    ]
  },
  "12_04-bee": {
    "description": '12_04-bee-ec2 instance, responsible for worker processes',
    "autoscale": {
      "timeout": 120,
      "node_min": 2,
      "node_max": 2
    },
    "instance_type": "m1.large",
    "security_groups": ["bee"],
    "default_attributes": {
      "other_key": "value"
    },
    "run_list": [
      "recipe[seatgeek-service::api-workers]",
      "recipe[seatgeek-service::cronq-workers]",
      "recipe[seatgeek-service::djjob]"
    ]
  },
  "12_04-www": {
    "description": "www-ec2 instance, responsible for the seatgeek frontend site",
    "instance_type": "m3.xlarge",
    "security_groups": ["www"],
    "run_list": [
      "recipe[seatgeek::customer-web]"
    ]
  }
}
```

### Merge rules

Each node *group* inherits from `__base__`, with some rules:

- Lists of items are appended to each other. `__base__` + `www`
- Dicts are merged at level 1.
- For all other other types, the child overrides the parent.

## Command line utility

We will have a simple command (name tbd):

```bash
package
```

That can take a `namespace:action`:

```bash
package <namespace>:<action>
```

And then optional group name filtering:

```bash
package <namespace>:<action> (group)
```

Of course, there would be other command line arguments:

```bash
package <namespace>:<action> (group) --arg value
```

### Available actions

```bash
package packer:create (group)
package packer:run (group)
package packer:clean (group) -n 10
package packer:delete (group)

package role:create (group)

package autoscale:create (group)
package autoscale:run (group)
package autoscale:update (group)

package instance:create (group) --key path/to/key.pem --name INSTANCE-NAME  (--zone name-of-zone)
package instance:deploy (group) -n 10
```

### Generating chef roles

Each node group should be able to generate a role:

```bash
package role:create 12_04-bee
```

For our above example, this would provide the following:

```javascript
{
    "name": "role-12_04-bee",
    "chef_type": "role",
    "json_class": "Chef::Role",
    "description": "12_04-bee-ec2 instance, responsible for worker processes",
    "override_attributes": {},
    "default_attributes": {
        "environment": "production",
        "key": "value",
        "other_key": "value"
    },
    "run_list": [
        "role[seatgeek::server]",
        "recipe[seatgeek::collect-services]",
        "recipe[seatgeek::decommission-services]",
        "recipe[seatgeek-service::api-workers]",
        "recipe[seatgeek-service::cronq-workers]",
        "recipe[seatgeek-service::djjob]",
        "recipe[seatgeek::notify-services]",
        "recipe[sudo::default]"
    ]
}
```

Some notes:

- There is a `post_run_list` in the `__base__` group. This is appended to the end of the `12_04-bee` run list, which is quite useful in terms of ensuring things happen in the appropriate order.
-  Node groups should strive to avoid using sub-roles for anything. Doing so makes it a bit difficult to traverse the structure of what is occuring.
-  The run_list should avoid the inclusion of recipes such as `vftp::default` or `git::client`. Instead, we should include these dependencies in the service we are running. If `seatgeek::api-workers` requires `vftp::default`, then we should have that dependency within that recipe.

#### Updating a role

If you ever touch `nodes.json` to add extra capabilities, you'll want to update your existing roles:

```bash
package roles:update 12_04-bee
```

Of course, this won't update nodes, which you'll have to do separately.

### Generating Packer images

Running the following command:

```bash
package packer:create 12_04-bee
```

Will generate the following packer json:

```javascript
{
  "builders": [{
    "type": "amazon-ebs",
    "access_key": "ACCESS_KEY",
    "secret_key": "SECRET_KEY",
    "region": "us-east-1",
    "source_ami": "ami-1ebb2077",
    "instance_type": "m1.large",
    "ssh_username": "ubuntu",
    "ami_name": "12_04-bee {{timestamp}}"
  }],
  ... # TBD: other stuff here related to building the ami
}
```

The above would be based on some sort of templating language.

#### Running

Actually creating the ami on AWS for later use would be nice:

```bash
package packer:run 12_04-bee
```

We will likely want to clean up older versions of the ami to save money:

```bash
package packer:clean 12_04-bee -n 10 # keep the last 10 amis
```

If a node group will never be used again, we can simply delete all amis from aws and the related packer.json:

```bash
# this will not delete any other local files or any ASGs
package packer:delete 12_04-bee
```

### Autoscale Group Integration

#### Creating an ASG

If we want to create an autoscale group, you could run the following command:

```bash
package autoscale:create 12_04-bee
```

This would create the following asg `dna` file in `dna/asg/12_04-bee.json`:

```javascript
{
  "id": "12_04-bee",
  "run_list": [
    "role[role-12_04-bee]"
  ]
}
```

It would also run `package role:create 12_04-bee` for the role dependency. Your tooling could then do as it likes regarding the running of this dna file.

Next you'll want to actually start any ASGs:

```bash
package autoscale:run 12_04-bee
```

This will create the required ASG - or error if one exists! - with the tag `group:12_04-bee`. Integrating chef runs wih bootstrapped data is outside of the scope of this document.

> Undefined behavior: What are the ASG defaults? We should use sane ones.

#### Updating an ASG

> This is slightly messy, and due to the notification system (see next section), it may not be entirely necessary.

If a node significantly changes - such as the size of the instance, or even base ami - we will likely want to reprovision the autoscale group:

```bash
package autoscale:update 12_04-bee
```

This would:

- provision a new `12_04-bee` asg
- wait until all the nodes in this asg are up and running - **(how?)**
- turn off the old autoscale group after a configurable timeout so that every other node has a chance to update - **(how?)**

### Procuring an instance

There will be cases where an ASG makes no sense, or we'd like to run a node in a one-off fashion:

```bash
package instance:create <group> --key path/to/key.pem --name INSTANCE-NAME  (--zone name-of-zone)
```

This will:

- Create an instance of type `<group>` with the name specified by the `--name` flag in the `--zone` (random if unspecified) using the key available at `--key`.

You can then run `chef-solo` using whatever tool you feel necessary.

> This does not create a DNA file, so running things will be weird. Should create some sort of dna file, even if it's not an ASG. Could be named `<group>-<instance-id>.json`.

### Deploying instances

It would be nice to be able to kick off a deployment of all nodes:

```bash
package instance:deploy
```

Or a specific subset of nodes:

```bash
package instance:deploy 12_04-bee
```

This could be helpful in the following circumstances:

- catastrophic events, such as an AWS zone going away
- adding a new person's key
- adding an infrastructure-wide dependency (`fail2ban` for instance)

## Chef running

### Sample recipe


The following is an example for `recipe[seatgeek-service::api-workers]`:

```ruby
include_recipe "python::default"

codebase = data_bag_item('codebases', 'api')

s3_file "shared/seatgeek/geoip.db" do
    path "/data/shared/geoip.db"
end

# pulls from the api-workers databag
# retrieves the required codebase
# sets up the circus watchers
# starts the service
seatgeek_circus "api-workers" do
    action :create
end
```

In our case, running an api worker would require the geoip database, as well as the `api` codebase. We also set `node['services']['api-workers'] = true` in order to notify further applications that this is available.

### Service collection

The `seatgeek::collect-services` recipe would parse the `run_list` to figure out what services are running on this box:

```ruby
# psuedo-code
for item in run_list:
    if item not in cookbook[seatgeek-service]:
        continue

    node.default['seatgeek-services']['available'][item] = true

for service in cookbook[seatgeek-service]:
    # configuration is some library that talks to an external service, such as etcd
    where = configuration.get_servers(service)
    if node['seatgeek-services']['available'][service]:
        where = where + current_node

    node.default['seatgeek-services']['services'][service] = where
```

Consequently, we could depend upon `node['seatgeek-services']['services']['api-workers']` containing a list of servers where `api-workers` is available. This is more useful for web contexts, where we might depend upon the exist of a `recommendation` service, for example.

> This has no provisions for services/datastores that must be synced. For example, it would be difficult to maintain the state of a rabbitmq cluster in this method. Also, if nodes are being provisioned simultaneously, it would similarly be annoying to reprovision things.

### Service decommissioning

If you are decommissioning a service, you should delete anything that service depends upon. This is important because you don't want to run code where it does not belong.

```ruby
# psuedo-code
for service, available in node['seatgeek-services']['available']:
    if not available:
        include_recipe "seatgeek-service::delete-#{service}"
        configuration.notify(service, available)
```

> If a service continues to maintain it's state on a node - for example, a the `api-worker` service was never removed from this service - then the notification system actually doesn't do anything.

All services should be deletable. Chef doesn't make it easy to contain the creation/deletion code for a particular thing in a single recipe, thus the hack of using a separate recipe.

> This could result in service drift, where the deployment of a service does not necessarily match up with it's undeployment

We want to notify everyone that a service is unavailable BEFORE taking the service away. This will hopefully ensure those services stop pointing at this resource, potentially helping with uptime.

### Service notification

This bit is actually quite easy. Once a server is deployed, we can notify all other servers of it's existence:

```ruby
# psuedo-code
for item, available in node['seatgeek-services']['available']:
    if available:
        configuration.notify(item, available)
```

We essentially want to notify everyone that we are *running* a service.

> If a service continues to maintain it's state on a node - for example, a the `api-worker` service was never removed from this service - then the notification system actually doesn't do anything.

The interesting thing here would be to run a daemon on every server that listens on this queue. Whenever a service becomes available/unavailable on a server, other servers can simply queue up the provision step of `chef-solo`.

## Workflow

Generally speaking, we would want to simplify ops-life. I don't know if the following workflow is necessarily:

- simple
- good
- a solid workflow

Having not tried it, I cannot endorse it. It *seems* legit.

### Completely new, standalone services

An operations engineer should be able to go about his day, working on a feature:

```bash
git add data_bags
git add vftp
git add seatgeek-service/recipes/ftp-listener.rb
git add seatgeek-service/recipes/ftp-processor.rb
git commit -m "added service to process ftp uploads"
```

And then setup instances for this:

```bash
# edit nodes.json to add ftp-processor and ftp-listener roles

package role:create ftp-listener
package role:create ftp-processor

git add nodes.json
git add roles/ftp-processor.json roles/ftp-listener.json
git commit -m "ftp-processor and ftp-listener role"

package packer:create ftp-listener
package packer:run ftp-listener

package packer:create ftp-processor
package packer:run ftp-processor
```

And finally bring them up in an autoscale group:

```bash
package autoscale:create ftp-processor
package autoscale:run ftp-processor

package autoscale:create ftp-processor
package autoscale:run ftp-processor
```

### Existing services

What if we had catch-all background workers, and were just deploying some new background worker that processes user analytics?

```bash
# work on seatgeek-service::process-users which requires access to temporary storage
# meaning we want to ensure the temporary storage is there, in addition to the service itself running.

git add data_bags
git add seatgeek-service/recipes/process-users.rb
git commit -m "create a process for playing with user"

# add the role to the 12_04-bee entry in nodes.json
package roles:update 12_04-bee
git add nodes.json roles/12_04-bee.json
git commit -m "added user processing to 12_04-bee machines"
```

We should be able to notify nodes to redeploy in some fashion.

```bash
package instance:deploy 12_04-bee
```

## Final Thoughts

This is likely step 1 towards a PaaS. Managing services here is still difficult, though relatively less so due to the tooling built around it. And the tooling does not exist yet.

Services are not completely isolated from each other, so it is possible for a single service to consume all the resources on a node. By the same token, it is possible for a node to consume no resources yet still be deployed to a server, thus costing the company money for no reason. Further integration with Autoscale groups *could* ameliorate this issue, but not without some sort of resource monitoring to figure out if processes are:

- doing enough work to warrant staying alive
- flooded with work

I have yet to see a heroku-like service that allows you to tie services together as dependencies. Likely you'll have some background workers that consumes an HTTP service, which I have not seen be autoconfigurable on something like Heroku. Being able to specify what you expose is *quite* useful, and a possible solution is to tie something like `haproxy`+`etcd` on each node to do service-level proxying. I am unsure as to whether this will flood nodes at any scale, though haproxy alone has worked well enough. This also means all your web services should expose some sort of status endpoint.

> The above applies to datastores, and luckily enough, if you are using a managed datastore by AWS, most of the issues are covered, though if they have an outage, you have an outage, so be warned.

Scaling up resources using the above workflow would be a challenge, as would moving services around. It could work well if everything was on it's own server, but that's unlikely to be economically feasible. That's essentially how Heroku works - you pay per dyno, though they probably have large instances hosting said dynos - so you can see some of the economics in action there.

This setup does not currently advocate immutable servers, though it does not preclude their usage. It actually *should* work, provided network traffic could be migrated from live nodes to dead nodes easily. The way to do that would be to remove a service from a node, which would trigger a deploy event across your infrastructure.

Testing deploys would be difficult. What if you deployed a bad configuration, bringing that node into production? Ideally you deploy to a testing/staging environment to shake out any cobwebs, but this might not be feasible depending upon your size. It could also be possible to test everything out locally through the use of Vagrant, but stuff like datastores and ebs volumes might be more difficult to fake out.
