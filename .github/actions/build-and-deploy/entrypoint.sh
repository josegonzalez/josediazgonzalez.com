#!/usr/bin/env bash
set -eo pipefail
[[ -n "$TRACE" ]] && set -x

main() {
  local MAINTAINER="$(echo "$GITHUB_REPOSITORY" | cut -d '/' -f1)"
  local REPOSITORY_URL="https://${MAINTAINER}:${JEKYLL_GITHUB_ACCESS_TOKEN}@github.com/${SITE_REPOSITORY}.git"

  if [[ -z "$JEKYLL_GITHUB_ACCESS_TOKEN" ]]; then
    echo "::error file=entrypoint.sh,line=8,col=2::Missing JEKYLL_GITHUB_ACCESS_TOKEN"
    return 1
  fi

  if [[ -z "$SITE_REPOSITORY" ]]; then
    echo "::error file=entrypoint.sh,line=13,col=2::Missing SITE_REPOSITORY"
    return 1
  fi

  echo "-----> Ruby version"
  ruby -v | sed -u "s/^/       /"

  echo "-----> Cloning site repository"
  if [[ -n "$TRACE" ]]; then
    git clone "$REPOSITORY_URL" _site | sed -u "s/^/       /"
    ls -lah _site | sed -u "s/^/       /"
  else
    git clone "$REPOSITORY_URL" _site > /dev/null 2>&1 | sed -u "s/^/       /"
  fi

  echo "-----> Building site"
  jekyll build | sed -u "s/^/       /"

  pushd _site > /dev/null
  ls -lah . | sed -u "s/^/       /"

  echo "-----> Configuring git for push"
  su-exec jekyll git config user.name "$GITHUB_ACTOR" | sed -u "s/^/       /"
  su-exec jekyll git config user.email "${GITHUB_ACTOR}@users.noreply.github.com" | sed -u "s/^/       /"

  echo "-----> Committing changes"
  su-exec jekyll git add . | sed -u "s/^/       /"
  su-exec jekyll git commit -m 'Jekyll Build from Action' | sed -u "s/^/       /"

  echo "-----> Pushing code"
  su-exec jekyll git remote set-url origin "$REPOSITORY_URL" | sed -u "s/^/       /"
  su-exec jekyll git push origin master | sed -u "s/^/       /"

  popd > /dev/null
  echo "=====> Push complete"
}

main "$@"
