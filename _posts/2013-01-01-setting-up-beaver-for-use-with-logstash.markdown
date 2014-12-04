---
  title:       "Using Beaver to ship log files to Redis/Logstash"
  date:        2013-01-01 23:34
  description: This post will guide you through a simple Beaver installation.
  category:    Opschops
  tags:
    - beaver
    - logs
    - logstash
  comments:    true
  sharing:     true
  published:   true
  layout:      post
---

Beaver is a lightweight python log file shipper that is used to send logs to an intermediate broker for further processing by Logstash. Brokers are simply middlemen that hold one or more log lines in josn_event format. I like to think of them as a staging area from which one or more logstash-indexers can retrieve events for further processing.

Beaver's explicit goal is to provide a shipper that can be used in environments where one or more of the following is true:

- Operations cannot support the JVM on an instance
- Developers are more experienced with debugging Python performance issues
- The server does not have enough memory for a large JVM application
- Simply shipping logs to an intermediary for later processing is enough

I actually built it for all of the above reasons. I wanted to process all application logs, but my webapp instances were `c1.medium` instances on AWS, and I needed both the memory and cpu for PHP. My service boxes were already overloaded, and I wanted to ensure any instances running varnish were not impacted by stupidities in just shipping logs.

I did, however, still want those log lines, so I set about writing a small daemon to send log lines to Redis. Redis is my preferred broker, because insertion is very fast and it is easy to inspect.

To start, we need to install Beaver:

```shell
pip install --update Beaver
```

This will retrieve the latest version of Beaver - version 18 as of this writing - via pip. It's possible to install via `easy_install`, but pip will ensure requirements are set.

{% blockquote %}
Please note that while I specify `Python 2.7`, you *may* actually be able to get away with `Python 2.6`. Every so often a build will break compatibility because I don't test against 2.6, but it currently does work just fine.
{% endblockquote %}

Running beaver is relatively straightforward:

```shell
beaver -c /etc/beaver/beaver.conf
```

In the above example, I tell beaver to run using a configuration file located at `/etc/beaver/beaver.conf`. Beaver takes configuration via arguments as well as via a configuration file, though I've found using a configuration file is much more flexible. Certain options can only be set via configuration file, so the above is how I recommend running beaver.

Once running, it will read your configuration from that file. An example for an api running under varnish is as follows:

```generic
[beaver]
transport: redis
redis_url: redis://localhost:6380/0
redis_namespace: logstash:cache:production
ssh_key_file: /etc/beaver/id_rsa
ssh_tunnel: deploy@redis-internal
ssh_tunnel_port: 6380
ssh_remote_host: redis-internal
ssh_remote_port: 6379
[/mnt/varnish/log/*.log]
tags: cache,varnish
type: cache:production
```

My configuration file has two stanzas. The first is a general configuration stanza. Beaver supports optional ssh tunneling, which is useful if you are going across datacenters. Those options are prefixed with `ssh_`. I also specify the url for redis, in this case using the tunnel port.

Note that for most transports that preserve some state, you can configure the exchange/namespace used. I've set a namespace of `logstash:cache:production` for this application, and use a different namespace for other apps. This is very useful for multiline logs that need to be later parsed by logstash as a single event.

I also have a stanza for a particular glob path for beaver to follow. In this case, it's following any logfile in `/mnt/varnish/log`. I can also specify tags and the type for the logs that fall under this globpath, which is quite useful when later processing in logstash.

Once started, beaver will ship my logs via a redis `pipeline` to my redis instance, where logstash picks up the work quite easily. The following is my logstash `indexer.conf`:

```generic
input {
  # Read from the redis list
  redis {
    host => 'redis-internal'
    data_type => 'list'
    key => 'logstash:cache:production'
    type => 'cache:production'
    threads => 2
  }
}

filter {
  # Pull out my varnish logs in combined apache log format
  grok {
    patterns_dir => "/etc/logstash/patterns"
    tags => ["cache"]
    pattern => "%{COMBINEDAPACHELOG}"
  }

  # Override the beaver provided timestamp info in favor of a more correct one
  date {
    tags => ["cache"]
    timestamp => "dd/MMM/yyyy:HH:mm:ss Z"
  }

  # Properly parse the request uri as a url
  grok {
    patterns_dir => "/etc/logstash/patterns"
    tags => ["cache"]
    match => [
      "request", "%{URIPROTO:uriproto}://(?:%{USER:user}(?::[^@]*)?@)?(?:%{URIHOST:urihost})?(?:%{URIPATHPARAM:querystring})?"
    ]
  }

  # Remove unneeded fields and fix up the querystring a bit
  mutate {
    tags => ["cache"]
    remove => [ "agent", "auth", "bytes", "httpversion", "ident", "referrer", "timestamp", "verb" ]
    gsub => [
      "querystring", "&", " ",
      "querystring", "/events\?", ""
    ]
  }

  # Parse out the querystring as a key => value hash so that we can analyze this later
  kv {
    tags => ["cache"]
    fields => ["querystring"]
  }

  # Url Decode the query. Would be nice to be able to specify this on a glob of fields, but whatever
  urldecode {
    tags => ["jerry", "varnish"]
    field => "q"
  }

  # Remove some unneeded apache log info, as well as the duplicative @source field
  # Also add a q_analyzed field so that we have both an analyzed and non-analyzed version of the search query
  mutate {
    tags => ["cache"]
    remove => [ "port", "querystring", "request", "urihost", "uriproto", "@source" ]
    replace => [ "q_analyzed", "%{q}", ]
  }
}

output {
  # Output everything to my logstash cluster sitting behind haproxy
  elasticsearch {
    host => "localhost:1337"
  }
}
```

I've documented everything above, and it's fairly straightforward as to whats happening. There are some gotchas with creating key-value pairs - I had to replace the `&` characters in the querystring with space ` ` characters - but nothing that won't be fixed in logstash in the future.

For those looking to get into grok, there is a [grokdebug heroku app](http://grokdebug.herokuapp.com/) for testing grok filters. Note that sometimes the patterns shipped with your version of logstash will be out of date with `grokdebug`, and so I recommend retrieving the patterns from the logstash repo and placing them in `/etc/logstash/patterns`. I do so and you can see I specified a pattern directory above in my grok usage.

Getting into log parsing is a bit of trail and error at first, and while I hope the process gets better in the future, hopefully this guide helps others get going.
