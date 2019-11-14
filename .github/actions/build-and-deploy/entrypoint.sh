#!/usr/bin/env bash
set -eo pipefail

main() {
  local MAINTAINER="$(echo "$GITHUB_REPOSITORY" | cut -d '/' -f1)"
  local REPOSITORY_URL="https://${MAINTAINER}:${JEKYLL_GITHUB_ACCESS_TOKEN}@github.com/${GITHUB_REPOSITORY}.git"

  if [[ -z "$JEKYLL_GITHUB_ACCESS_TOKEN" ]]; then
    echo "::error file=entrypoint.sh,line=8,col=2::Missing JEKYLL_GITHUB_ACCESS_TOKEN"
    return 1
  fi

  echo "-----> Building site"
  jekyll build | sed "s/^/       /"

  echo "-----> Configuring git for push"
  git config user.name "$GITHUB_ACTOR" | sed "s/^/       /"
  git config user.email "${GITHUB_ACTOR}@users.noreply.github.com" | sed "s/^/       /"

  echo "-----> Committing changes"
  git add _site | sed "s/^/       /"
  git commit -m 'Jekyll Build from Action' | sed "s/^/       /"

  echo "-----> Pushing code"
  git push origin master | sed "s/^/       /"

  popd > /dev/null
  echo "=====> Push complete"
}

main "$@"
