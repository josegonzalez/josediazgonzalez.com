---
  title:       "Deploy ALL the things using simple Bash scripts"
  date:        2013-12-17 05:51
  description: "Automate everything, including your deploys, using things as simple as a bash script"
  category:    cakephp
  tags:
    - bash
    - cakeadvent-2013
    - cakephp
    - deployment
  comments:    true
  sharing:     true
  published:   true
  layout:      post
  series:      CakeAdvent-2013
---

This is a post about simple CakePHP application deployment. We'll use the `bash` language to deploy our application.

## Some setup

Let's start by defining a new bash file in the base of our repository called `deploy`:

```shell
#!/bin/sh
#
# Deploy Script
#
# Makes heavy use of git features to manage quickly deploying
# to both staging and production environments.
#
```

You should execute the command `chmod +x deploy` in order to give it executable permissions. Next, lets add a few configuration variables:

```shell
# Colors
COLOR_OFF="\033[0m"   # unsets color to term fg color
RED="\033[0;31m"      # red
GREEN="\033[0;32m"    # green
YELLOW="\033[0;33m"   # yellow
MAGENTA="\033[0;35m"  # magenta
CYAN="\033[0;36m"     # cyan

DEPLOY_USER="deploy"

STAGING_SERVER="staging.example.com"
# This directory should contain:
# - `current` directory: contains your git repository
# - `shared` directory: can contain shared files and folders
STAGING_DIR="/apps/staging/example.com"
STAGING_SSH_PORT=22

PRODUCTION_SERVER="example.com"
# This directory should contain:
# - `current` directory: contains your git repository
# - `shared` directory: can contain shared files and folders
PRODUCTION_DIR="/apps/production/example.com"
PRODUCTION_SSH_PORT=22
```

> Having a deploy user is a good practice, and I recommend doing so in order to remove your own ssh user from the equation.

We've defined a few colors for use within our deploy process, as well as configuration for both staging and production. You can modify the paths and configuration as you see fit.

## Meat and Latvian Potatos

Now lets add some meat to our deploy script. The following bit will control how the script reacts to different arguments:

```shell
case $1 in
  staging)
    echo "\n${GREEN}DEPLOYING APP TO STAGING${COLOR_OFF}\n"

    # Updates origin/staging to specified branch (default origin/master)
    # and deploys it to staging_server
    old_revision=`git rev-parse origin/staging`
    tag_nonproduction staging $2
    new_revision=`git rev-parse origin/staging`

    deploy_staging
    echo "\n${CYAN}APP DEPLOYED!${COLOR_OFF}\n"
    ;;
  production)
    echo "\n${GREEN}DEPLOYING APP TO PRODUCTION${COLOR_OFF}\n"

    # Deploys origin/production to production_server
    old_revision=`git rev-parse origin/production`
    tag_production
    new_revision=`git rev-parse origin/production`

    deploy_production

    echo "\n${CYAN}APP DEPLOYED!${COLOR_OFF}\n"
    ;;
  restart_workers)
    echo "\n${GREEN}RESTARTING PRODUCTION WORKERS${COLOR_OFF}\n"
    restart_production_workers
    echo "\n${CYAN}WORKERS RESTARTED!${COLOR_OFF}\n"
    ;;
  current)
    environment=$2
    if [ -e $2 ]; then
      environment="production"
    fi

    deployed_commit=`git rev-parse origin/$environment 2>/dev/null`
    if [[ "$deployed_commit" == *origin/* ]]; then
      echo "$environment: Nothing deployed"
    else
      echo "$environment: Deployed hash $deployed_commit"
    fi
    ;;
  *)
    echo "USAGE: $0 {staging|production|current|restart_workers}"
    exit
    ;;
esac
```

There are a few moving parts here, so lets review:

- `deploy staging $BRANCH` will deploy a given branch to staging
- `deploy production` will deploy `master` branch to production
- `deploy current $ENVIRONMENT` will display whatever the current deployed version is to a given environment
- `deploy restart_workers` will restart the production workers
- Deploys will change the branch associated with an environment to whatever it is you are deploying. For instance, deploying `test` branch to the staging environment will result in the `staging` branch becoming a pointer to the current commit on the `test` branch

We still don't have many of the functions referenced, so lets define them. Please place them *before* the case/switch statement.

### `restart_production_workers`

```shell
restart_production_workers() {
  ssh -p $PRODUCTION_SSH_PORT $DEPLOY_USER@$PRODUCTION_SERVER "cd $PRODUCTION_DIR/current &&\
    echo -e \"${YELLOW}--->${COLOR_OFF} Stopping workers \" &&\
    CAKE_ENV=production app/Console/cake CakeResque.cake_resque stop --all>/dev/null &&\
    echo -e \"${YELLOW}--->${COLOR_OFF} Starting ${MAGENTA}[email, default]${COLOR_OFF} workers \" &&\
    CAKE_ENV=production app/Console/cake CakeResque.cake_resque start --workers 1 --queue email,default --interval 5"
}
```

This command is custom to my own setup. It will stop my CakeResque workers and restart them. Nothing too weird here. I have to define my `CAKE_ENV` as configuration for this app is controlled via an environment (which we'll discuss in a later post).

### `deploy_production`

```shell
deploy_production() {
  ssh -p $PRODUCTION_SSH_PORT $DEPLOY_USER@$PRODUCTION_SERVER "cd $PRODUCTION_DIR/current &&\
    echo -e \"${YELLOW}--->${COLOR_OFF} Fetching changes\" &&\
    git fetch -q &&\
    echo -e \"${YELLOW}--->${COLOR_OFF} Checking out production branch\" &&\
    git reset -q --hard origin/production &&\
    echo -e \"${YELLOW}--->${COLOR_OFF} Clearing cache\" &&\
    sudo rm -rf ../shared/tmp/cache/models/* ../shared/tmp/cache/persistent/* ../shared/tmp/cache/views/* &&\
    echo -e \"${YELLOW}--->${COLOR_OFF} Creating tmp folders\" &&\
    sudo mkdir -p ../shared/tmp/cache/models ../shared/tmp/cache/persistent ../shared/tmp/cache/views ../shared/tmp/sessions ../shared/tmp/logs &&\
    echo -e \"${YELLOW}--->${COLOR_OFF} Making tmp writeable\" &&\
    sudo chmod -R 777 ../shared/tmp/* &&\
    echo -e \"${YELLOW}--->${COLOR_OFF} Removing old files and symlinks\" &&\
    rm -rf app/webroot/test.php app/tmp &&\
    echo -e \"${YELLOW}--->${COLOR_OFF} Symlinking tmp\" &&\
    ln -sf $STAGING_DIR/shared/tmp app/tmp"
}
```

`deploy_production` does the following:

- Fetches all codebase changes
- Checks out the production branch
- Clears the tmp cache and rebuilds it
- Fixes all old and new symlinks
- Removes the `test.php` file, which doesn't belong in production

### `deploy_staging`

```shell
deploy_staging() {
  ssh -p $STAGING_SSH_PORT $DEPLOY_USER@$STAGING_SERVER "cd $STAGING_DIR/current &&\
    echo -e \"${YELLOW}--->${COLOR_OFF} Fetching changes\" &&\
    git fetch -q &&\
    echo -e \"${YELLOW}--->${COLOR_OFF} Checking out staging branch\" &&\
    git reset -q --hard origin/staging &&\
    echo -e \"${YELLOW}--->${COLOR_OFF} Clearing cache\" &&\
    sudo rm -rf app/tmp/cache/models/* app/tmp/cache/persistent/* app/tmp/cache/views/* &&\
    echo -e \"${YELLOW}--->${COLOR_OFF} Creating tmp folders\" &&\
    sudo mkdir -p app/tmp/cache/models app/tmp/cache/persistent app/tmp/cache/views app/tmp/sessions app/tmp/logs &&\
    echo -e \"${YELLOW}--->${COLOR_OFF} Making tmp writeable\" &&\
    sudo chmod -R 777 app/tmp/* &&\
    echo -e \"${YELLOW}--->${COLOR_OFF} Removing old files and symlinks\" &&\
    rm -f app/webroot/test.php
}

```

`deploy_staging` does the following:

- Fetches all codebase changes
- Checks out the staging branch
- Clears the tmp cache and rebuilds it
- Fixes all old and new symlinks
- Removes the `test.php` file, which doesn't belong in production

Notably, we don't care about any downtime in staging, so all directory changes are done in-place as opposed to within a symlink.

### `tag_nonproduction`

```shell
tag_nonproduction() {
  verify_working_directory_clean

  local branch=$2
  if [ -e $2 ]; then
    branch="master"
  fi

  echo "${YELLOW}--->${COLOR_OFF} Marking staging branch"
  git fetch -q
  echo "${YELLOW}--->${COLOR_OFF} Creating local staging branch"
  git branch -q -f $1 origin/$branch
  echo "${YELLOW}--->${COLOR_OFF} Pushing staging branch to origin"
  git push -q -f origin $1
  echo "${YELLOW}--->${COLOR_OFF} Deleting local staging branch"
  git branch -q -D $1
}
```

Pretty straightforward. To tag the staging release, we:

- Verify a clean local working directory. We do much with the local repo, hence this necessary step.
- Create a local staging branch from whatever branch you specify
- Push the staging branch to your central repository
- Delete the local staging branch, as we don't need it.

### `production`

```shell
tag_production() {
  verify_working_directory_clean

  echo "${YELLOW}--->${COLOR_OFF} Pushing current master"
  git push -q origin master
  echo "${YELLOW}--->${COLOR_OFF} Fetching all changes"
  git fetch -q
  echo "${YELLOW}--->${COLOR_OFF} Creating local production branch"
  git branch -q -f production origin/master
  echo "${YELLOW}--->${COLOR_OFF} Pushing production branch to origin"
  git push -q -f origin production
  echo "${YELLOW}--->${COLOR_OFF} Deleting local production branch"
  git branch -q -D production
}
```

Also straightforward. To tag the production release, we:

- Verify a clean local working directory. We do much with the local repo, hence this necessary step.
- Push local changes up to the central repository, as that's likely what the developer desired.
- Create a local production branch from master
- Push the production branch to your central repository
- Delete the local production branch, as we don't need it.

### `verify_working_directory_clean`

```shell
verify_working_directory_clean() {
  git status | grep "working directory clean" &> /dev/null
  if [ ! $? -eq 0 ]; then # working directory is NOT clean
    echo "${RED}WARNING: You have uncomitted changes, you may have forgotten something${COLOR_OFF}\n"
    exit
  fi
}
```

We need to verify the current working directory because we don't want to accidentally break the local repository state. If everything has been pushed, then there is no danger in making potentially bad changes locally.

This also ensures that a developer deploys the code they think they should be deploying. For instance, if you make a change but forget to commit it, this check will give the develop a simple reminder to do so first.

## The output:

![http://cl.ly/image/1x3F3L3c1m23](http://cl.ly/image/1x3F3L3c1m23/Screen%20Shot%202013-12-17%20at%205.20.34%20PM.png)

We now have a simple way of deploying our applications. No more nasty ssh+git-pull exercises.
