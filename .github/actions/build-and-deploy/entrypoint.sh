#!/usr/bin/env bash
set -eo pipefail
[[ -n "$TRACE" ]] && set -x

main() {
  local MAINTAINER="$(echo "$GITHUB_REPOSITORY" | cut -d '/' -f1)"
  local REPOSITORY_URL="https://${MAINTAINER}:${JEKYLL_GITHUB_ACCESS_TOKEN}@github.com/${SITE_REPOSITORY}.git"

  if [[ -z "$SKIP_DEPLOY" ]]; then
    if [[ -z "$JEKYLL_GITHUB_ACCESS_TOKEN" ]]; then
      echo "::error file=entrypoint.sh,line=11,col=4::Missing JEKYLL_GITHUB_ACCESS_TOKEN"
      return 1
    fi

    if [[ -z "$SITE_REPOSITORY" ]]; then
      echo "::error file=entrypoint.sh,line=16,col=4::Missing SITE_REPOSITORY"
      return 1
    fi
  fi

  echo "-----> Ruby version"
  ruby -v | sed -u "s/^/       /"

  echo "-----> Installing gems"
  bundle install | sed -u "s/^/       /"

  echo "-----> Running tests"
  bundle exec rake test | sed -u "s/^/       /"

  if [[ -z "$SKIP_DEPLOY" ]]; then
    echo "-----> Cloning site repository"
    if [[ -n "$TRACE" ]]; then
      git clone "$REPOSITORY_URL" _site | sed -u "s/^/       /"
      ls -lah _site | sed -u "s/^/       /"
    else
      git clone "$REPOSITORY_URL" _site > /dev/null 2>&1 | sed -u "s/^/       /"
    fi
  fi

  echo "-----> Building site"
  bundle exec jekyll build | sed -u "s/^/       /"

  if [[ -n "$SKIP_DEPLOY" ]]; then
    echo "=====> Build complete, skipping deploy"
    return 0
  fi

  pushd _site > /dev/null
  ls -lah . | sed -u "s/^/       /"

  echo "-----> Configuring git for push"
  git config user.name "$GITHUB_ACTOR" | sed -u "s/^/       /"
  git config user.email "${GITHUB_ACTOR}@users.noreply.github.com" | sed -u "s/^/       /"

  echo "-----> Committing changes"
  git add . | sed -u "s/^/       /"
  git commit -m 'Jekyll Build from Action' | sed -u "s/^/       /"

  echo "-----> Pushing code"
  git remote set-url origin "$REPOSITORY_URL" | sed -u "s/^/       /"
  git push origin master | sed -u "s/^/       /"

  popd > /dev/null
  echo "=====> Push complete"
}

main "$@"
