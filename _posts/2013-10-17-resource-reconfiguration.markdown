---
  title:       "Resource reconfiguration"
  date:        2013-10-17 11:38
  description: How do you manage service configurations across a cluster of services?
  category:    Opschops
  tags:
    - chef
    - cofiguration
    - etcd
    - provisioning
  comments:    true
  sharing:     true
  published:   true
  layout:      post
  series:      Insane Server Management
---

As you head towards service-oriented architecture, continuous deployment, immutable servers and an ever-growing infrastructure, you inevitably come up against resource provisioning issues.

On a PaaS, you might have `100` nodes running `6` different services, each having dependencies upon datastores and other services. How do you route between each service to the correct external source?

One way to do it is by using environment variables:

```bash
export DATABASE_URL=mysql://user:password@host:port/database
export API_URL=http://internal-domain/mount
export ENV=production
./path/to/command --opts
```

This gets a bit messy because there may be several different environment variables, so eventually you may have something like:

```bash
cat > /etc/services.d/app.conf <<EOF
export DATABASE_URL=mysql://user:password@host:port/database
export API_URL=http://internal-domain/mount
export ENV=production
EOF

. /etc/services.d/app.conf ./path/to/command --opts
```

> Your user will require access to the `app.conf` file, so please keep this in mind when creating the file.

This `app.conf` file now contains environment variables for use with shell scripts. This works quite well for one-off tasks, or even cronfiles, though one thing you'll see is that it does not have provisions for ensuring tasks complete before the environment variables change. Breaking up long-running tasks into jobs can help this, but is outside the scope of this post.

How do you specify a requirement for a service? Perhaps a key-value hash with this information could work:

```json
{
  "id": "app-www",
  "environment": {
    "ENV": "production"
  },
  "requires": {
    "DATABASE_URL": "{PRIMARY_DATABASE_URL}",
    "API_URL": "{READONLY_API_URL}"
  }
  ... # other stuff
}
```

> Perhaps we specify `services` we depend upon, instead of environment variable requirements?


We could then look up the replacement values for these services and attach them as necessary.

Using a configuration management tool - such as Chef, Puppet, Ansible, etc. - will help you automate the update cycle for this file. A simple workflow could be:

{% ditaa %}
/------------+ etcd /------------+ trigger /-----------+
| www deploy |----->| lb watcher |-------->| lb deploy |
+------------+      +------------+         +-----------+
{% endditaa %}

You would depend upon a listener on an external service - perhaps `etcd`, perhaps `rabbitmq` - to ensure that resources are reprovisioned in other locations.

You also want to maintain what resources a specific service **provides**. If you can specify this, then an external service can keep track of the global system state and be used to monitor what is available where. For example, we might provision the `www-app` service, which could specify its exports thusly:

```json
{
  "id": "app-www",
  "provides": {
    "WWW_URL": "http://{host}:{port}/some-mount"
  },
  ... # other stuff
}
```

One issue here is that there is a definite lag between when you reprovision a server and when chef-solo on related servers will run/complete their run. If the only thing you are reprovisioning is where a service lives, you could simplify much of your manifest by moving that to a local load balancer.

## Full Deploy Cycle

The following is a full web service (in `data_bags/service/app-www.json`):

```json
{
  "id": "app-www",
  "command": true,
  "run_list": [
    "nginx::default",
    "php::fpm"
  ],
  "environment": {
    "ENV": "production"
    "PORT": 8080
  },
  "requires": {
    "DATABASE_URL": "{PRIMARY_DATABASE_URL}",
    "API_URL": "{READONLY_API_URL}"
  },
  "provides": {
    "WWW_URL": "http://{HOST}:{PORT}/some-mount"
  },
  "local_port": 8080
}
```

And the api service (in `data_bags/service/api.json`):

```json
{
  "id": "api",
  "command": true,
  "run_list": [
    "python::default",
    "python::virtualenv",
    "igraph::default",
    "igraph::python"
  ],
  "environment": {
    "ENV": "production",
    "PORT": 1100
  },
  "requires": {
    "DATABASE_URL": "{PRIMARY_DATABASE_URL}",
    "ELASTICSEARCH_URL": "{API_ELASTICSEARCH_CLUSTER_URL}"
  },
  "provides": {
    "API_URL": "http://{HOST}:{PORT}",
    "READONLY_API_URL": "http://{HOST}:{PORT}"
  },
  "local_port": 1100
}
```

We could have a set of general configuration attributes for external services/datastores (in `configuration/attributes/datastores.rb`):

```ruby
# For things not available from your configuration service for whatever reason
node.default['configuration']['datastores']['PRIMARY_DATABASE_URL'] = 'mysql://user:password@host:port/database'
node.default['configuration']['datastores']['API_ELASTICSEARCH_CLUSTER_URL'] = 'http://elastic-ec2-01,elastic-ec2-02:9200'
```

The process would look like:

1. deploy a new api node
  - api node reloads local load balancer with an entry for `API_URL` at the `local_port`.
  - api node notifies configuration service that the current server provides `API_URL` and `READONLY_API_URL`
  - external load balancer sees notification, reloads its code to add the entries for `API_URL` and `READONLY_API_URL
2. deploy a new www node
  - web node queries for requirements, specifically the `READONLY_API_URL`
  - web node configures itself
  - api node reloads local load balancer with an entry for `WWW_URL` at the `local_port`.
  - web node notifies configuration service that the current server provides `WWW_URL`
  - external load balancer sees notification, reloads its code to add an entry for `WWW_URL`

## Public and private services

This is quite important. We will have services that are available only internally, and thus should not be publicly routable. Thus, we should take care to specify whether a service is internal or external:


```json
{
  "id": "app-www",
  "public": true,
  ... # other stuff
}
```

Load balancers would thus be configured to either be internal load balancers or external, public facing ones. One improvement for internal load balancers would be to only include necessary services in the registry, thus relieving pressure on healthchecks for unneeded resources.

## Service Federation

As well, you may want to have federations of services that shouldn't take to each other. An example of this might be a startup's side project - http://pivot.ly for instance - which may be deployed by the same tooling, but should be segregated for PCI-Compliance.

```json
{
  "id": "app-www",
  "federation": "seatgeek",
  ... # other stuff
}
```

Federation could allow you to scope requirements to particular "regions" of your codebase. You could use this as a proxy for the app's `environment` - staging, production, testing, bob, etc. - or to segregate applications.

> Note that there would be no provisions for ensuring multiple federations are deployed to a single node. This should be handled in code somehow.

## Multiple Regions

Bring up necessary services in multiple regions, and ensure the datastores also exist in those regions. Specifying multiple bits of configuration per-region could be difficult.

## The single source of truth

This should be something that is:

- distributed
- highly available
- low latency
- has the ability to perform pub-sub
- low-cost of ownership

I'm looking at potentially using [`etcd`](https://github.com/coreos/etcd) here, as it seems well-maintained, and appears to have the attributes desired above.

> the datastructure has not been defined, so this is all up in the air.

### Listeners

Each service will `listen` for particular environment variable requirements. If they are updated, the listeners should start a provisioning step.

Note that we should collapse multiple waiting provisions into a single provision call. If you bring up 100 new web nodes, the load balancer should collapse the queued provisions into a single one. There should only ever be 1 queued provision at a time, as any existing subsequent provisions would be taken care of by the first one on the queue.

TODO: How does this work? We want as few moving parts as possible.

The listener *should* be a system-level service. When chef runs, it should pick up new keys to listen to on the fly. The provision-call could and should be an arbitrary command - what if you don't run chef-solo? etc. The listener should be one of, if not the, first thing to be installed on a given node, so that it can constantly listen for events. It should also keep track of whether chef-solo is running, in the interest of not re-running.

Note that we should be able to turn the listener on and off. If turned on, it should immediately queue up it's own provision step, as we wouldn't know what changed in the time it was off. To prevent a stampede of provisions due to failures in the service, we should write a file somewhere containing the last provision time, and throttling provisioning if there appear to be many calls within a certain timeframe.

TODO: Spec out how this works...
