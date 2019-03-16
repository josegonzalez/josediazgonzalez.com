FROM jekyll/jekyll:3.8.5

LABEL "com.github.actions.name"="jekyll-build-and-push"
LABEL "com.github.actions.description"="Builds a jekyll blog and pushes it to a remote site"
LABEL "com.github.actions.icon"="mic"
LABEL "com.github.actions.color"="purple"

LABEL "repository"="http://github.com/josegonzalez/josediazgonzalez.com"
LABEL "homepage"="http://github.com/josegonzalez/josediazgonzalez.com"
LABEL "maintainer"="Jose Diaz-Gonzalez <github-actions+josediazgonzalez.com@josediazgonzalez.com>"

ADD entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
