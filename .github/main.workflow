workflow "Jekyll build now" {
  resolves = [
    "Jekyll Action",
  ]
  on = "push"
}

action "Jekyll Action" {
  needs = "On master branch"
  uses = "./action-build/"
  secrets = [
    "JEKYLL_GITHUB_ACCESS_TOKEN",
    "SITE_REPOSITORY",
  ]
}

action "On master branch" {
  uses = "actions/bin/filter@d820d56839906464fb7a57d1b4e1741cf5183efa"
  args = "branch master"
}
