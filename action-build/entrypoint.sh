#!/usr/bin/env bash
set -eo pipefail

git clone "https://${GITHUB_TOKEN}@github.com/${SITE_REPOSITORY}.git" _site > /dev/null 2>&1

jekyll build

pushd _site > /dev/null

git remote add push "https://${GITHUB_TOKEN}@github.com/${SITE_REPOSITORY}.git"
git config user.name "${GITHUB_ACTOR}"
git config user.email "${GITHUB_ACTOR}@users.noreply.github.com"

git add . && \
  git commit -m 'jekyll build from Action' && \
  git push push master
