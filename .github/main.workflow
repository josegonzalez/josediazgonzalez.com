workflow "Jekyll build now" {
  resolves = [
    "Jekyll Action",
  ]
  on = "push"
}

action "Jekyll Action" {
  uses = "./action-build/"
  secrets = [
    "GITHUB_TOKEN",
    "SITE_REPOSITORY",
  ]
}
