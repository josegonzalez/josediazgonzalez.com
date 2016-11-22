---
  title:       "A Lambda PaaS"
  date:        2016-11-21 19:51
  description: ""
  category:    opschops
  tags:
    - deployment
    - infrastructure
    - serverless
  comments:    true
  sharing:     true
  published:   true
  layout:      post
  disable_advertisement: true
---

Infrastructure is a confusing beast to developers. Here are things you would have to learn about and manage:

- Proper Logging (and storage thereof)
- Application Configuration
- Deployment Pipelines
- Metric Collection
- Automatic Scaling
- Database Maintenance
- Environment Management (dev/staging/prod)

Unless you are using a PaaS, you are probably in a bad spot in one or more ways. If you're not, it is likely that you can go to the software company down the block and they would be doing all of these things *quite* differently than you are.

I'm not all-in on serverless application development, but some platforms get it right. Heroku certainly does, and AWS has nice pieces that can be used to implement the above - albeit in a jank ui. I was playing with a few bits of tech this weekend to make the experience a bit nicer, and here is a description of what I came up with.

## Pushing Code and Executing a Pipeline

> You'll need to be running a build server for this. Install docker on the instance, as we'll be using that. Also, install the `zip` utility.

This is probably the most boring part to me. I've already worked on a few systems that have this sort of functionality - Dokku being the biggest - but for this purpose, lets just use [go-gitreceive](https://github.com/coreos/go-gitreceive). You'll need to install it and initialize the `git` user, but once that is done, here is our stub `receiver` script that goes in `/home/git/receiver`.

```shell
#!/bin/bash
main() {
  local TMP_WORK_DIR=$(mktemp -d "/tmp/laambda.XXXX")
  trap 'rm -rf "$TMP_WORK_DIR" > /dev/null' RETURN INT TERM EXIT

  mkdir -p "$TMP_WORK_DIR" && cat | tar -x -C "$TMP_WORK_DIR"

  if [[ ! -f "$TMP_WORK_DIR/requirements.txt"]]; then
    echo "Invalid python application detected, bailing"
  fi

  # the rest of the script goes here
}

main "$@"
```

For my dummy implementation, I didn't keep the repository around, though you are welcome to do so using `git-upload-pack` if you have it installed on your server.

Note that you'll also need to add your ssh key to the server via `go-gitreceive upload-key git` or similar. Please read the docs for the referenced project.

## laambda (two As because its a PaaS)

> This system only supported Python because I don't believe in Node.JS. It doesn't exist, sorry. I also don't drink coffee, so Java is out.

One thing I hate about the current lambda deploy model is that it is annoying to build assets locally and then push that into the cloud. My Macbook isn't CentOS 7 with a bunch of funny bits changed, so I can't be sure my code will work *exactly* as I expect it to. The hack that a few people use is to build in a VM or an EC2 instance, but I'd like something slightly closer to Lambda's infrastructure. For that, I turned to the [docker-lambda](https://github.com/lambci/docker-lambda) project.

The docker-lambda project is more or less a replica of the Lambda container used on AWS. It does have a few changes - notably task runners are changed in order to be able to run outside of the AWS infrastructure - but overall is an easy to use replica of the Lambda environment. You can use it to build an application locally

Here is a quick test of how it might work for a given python application:

```shell
# make this configurable somehow ;)
APP_NAME=api

# cd into the app you want to build for lambda
cd "$TMP_WORK_DIR"

# in a docker container, do the following:
# - create a virtualenv
# - activate it
# - install your dependencies
# be sure to load up a volume for caching, or you're gonna have a bad time
docker run --rm \
    -v "$TMP_WORK_DIR":/var/task \
    -v /tmp/.cache:/root/.cache \
    lambci/lambda:build-python2.7 \
    bash -c 'virtualenv .virtualenv && source .virtualenv/bin/activate && pip install -r requirements.txt'

# move the built virtualenv out of the way for now
mv .virtualenv /tmp/.virtualenv
VIRTUAL_ENV=/tmp/.virtualenv

# create your initial zip file
zip -9 "/tmp/${APP_NAME}.zip"

# now zip up the site-packages for lib
cd $VIRTUAL_ENV/lib/python2.7/site-packages
zip -r9 "/tmp/${APP_NAME}.zip" *

# and also the site-packages for lib64
cd $VIRTUAL_ENV/lib64/python2.7/site-packages
zip -r9 "/tmp/${APP_NAME}.zip" *

# and now add all of your app code
cd "$TMP_WORK_DIR"
zip -g "/tmp/${APP_NAME}.zip" *
```

Pretty nifty I think. We've still got a bit of work to do.

## Specifying multiple functions

At this point in the game, while I do believe that it's a bit inflexible, the `Procfile` fits right into how we might specify commands. Lets say my codebase has two python files:

- `CreateThumbnail`
- `ResizeThumbnail`

Each one has a function called `handler`, which does all the work for our api. We could spend time coming up with yet another yaml format - oh joy, our developers will *love* learning a new format - or we could just use the following Procfile:

```yaml
create: CreateThumbnail.handler
resize: ResizeThumbnail.handler
```

Seems pretty reasonable to me. No, it doesn't specify any extra info, like memory, timeout, iam profile, etc., but all those can have "sane" defaults within our `laambda` PaaS. We'll get into that later. Lets assume the following are the defaults:

- `region`: `us-east-1`, the best region
- `function-name`: The name of the codebase (`api` in this case), suffixed with the entry in the Procfile (`create` or `resize`)
- `runtime`: `python2.7`. No other runtimes exist, remember?
- `timeout`: `10`
- `memory-size`: `1024`

The following will need to be specified on app creation:

- `role`: An arn role for your function

Since you have the zip file, you can just run your `aws` command for each function to upload the codebase like normal:

```shell
aws lambda create-function \
  --region "$REGION" \
  --function-name "$FUNCTION_MAME" \
  --zip-file "fileb://tmp/${APP_NAME}.zip" \
  --role "$ROLE_ARN" \
  --handler "$FUNCTION_HANDLER" \
  --runtime "$RUNTIME" \
  --timeout "$TIMEOUT" \
  --memory-size "$MEMORY_SIZE"
```

Pretty good, I think.

## Managing the Lambda functions

No one wants to remember the `aws lambda` cli, so provide your developers with the tooling to manage that sort of thing. For my test, I configured the event sources on the web ui, but you might want to have a cli like the following:

```shell
# manage event sources
laambda event-sources        FUNCTION
laambda event-sources:add    FUNCTION SOURCE_HERE
laambda event-sources:remove FUNCTION SOURCE_HERE
laambda event-sources:clear  FUNCTION SOURCE_HERE
```

Similarly, any bit that can be managed by the `aws lambda` cli should be handled by your tooling. I implemented the following handlers for my own purposes:

```shell
# manage configuration
# all functions in an app have access to the same env in my model
laambda config
laambda config:get KEY
laambda config:set KEY=VALUE
laambda config:unset KEY
laambda config:clear

# manage resources
laambda resource:memory FUNCTION VALUE
laambda resource:timeout FUNCTION VALUE
```

I'd imagine it would be a good idea to also handle VPC configuration, KMS encryption keys, roles associated with your function, and anything else either not version controlled or that AWS exposes in the future.

## Rollbacks

One nice thing about Heroku is that you can rollback in time to basically any state of your application. Like it or not, a developer (and the ops folks!) will screw things up eventually, so turning back the clock is almost assuredly necessary.

Ideally, you are storing your app configuration in a distributed, encrypted k/v, *outside* of Lambda. This will allow you to maintain some notion of state. I have no real recommendations here, other than to keep the following for each changeset:

- A reference to the built zip file (likely as a hash of the codebase) which you may want to store on S3
- An encrypted bag of the current configuration for every function within an APP.
- A description of the changes (config change, deploy, etc.)

You should also be able to list these changesets so that you actually know what went down. I'd build the following:

```shell
laambda releases
```

And give it some sort of `git changelog` style output.

## Further considerations

Some questions you'll want to answer:

- Where are you storing logs?
  - The easiest is Cloudwatch, though honestly the UI kinda blows. You can probably get away with shipping them elsewhere, like an external service - Honeycomb.io, Logentries, Papertrail all would work - or you can ship them to whatever centralized logging system you have - the ELK stack and Graylog are popular ones. Just also expose the logs via the same cli tooling you built to manage this thing.
- How are you collecting metrics?
  - The same applies here as does for logging. The big issue with either is DNS, as Lambda functions aren't necessarily listening to your custom DNS server. I'd likely setup a simple Grafana/Graphite/StatsD setup and go from there.
- How do you test functions?
  - Be sure to setup multiple environments. Your tooling could take a `--env` flag to specify a VPC, for instance, and you'd simply partition environments based on the VPC.

Other enhancements you may want to consider:

- The system above has no authentication, so anyone with ssh access can push to any application.
- While developers are fine with a CLI, they'll also be hurting for a web ui. Having a web ui will also allow you to personally audit what is going on, without needing to depend upon the developer to paste the output. If you have a web ui, build an API that does all the coordination for your CLI tool, instead of having that CLI tool be a crappy wrapper around `awscli`.
- Your system *is* capable of continuous deployment, and I highly encourage that model.
- You could add support for each AWS Lambda runtime by detecting the language in use on deploy. We added a small amount of python detection to our `go-gitreceive` handler, though you can expand on that quite easily. I would suggest looking into the heroku buildpack model for figuring out how to properly detect and install each "runtime".
- None of this handles the local development cycle of a Laambda function.
- Autoscale your build servers. You'll have some issues around having the same dependency cache - get around that by uploading/downloading it from S3 - but it will allow you to weather an outage of your build servers. Route53 can be set to round-robbin DNS requests with healthchecks, making it easy to perform maintenance on your build environment.
- Promoting apps from environment to environment, or even allowing "pull request" apps to be deployed in a specific environment, would allow developers to gain confidence in what they are deploying. Heroku has PR apps, so why shouldn't you?

I do think that services like Lambda provide an excellent framework for building applications, but we should start thinking about how we'd like to interact with these services, instead of how these services force us to interact with them.

> Why isn't this *also* a thing for EMR? Or really any similar kind of service?
