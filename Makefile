SITE_REPOSITORY ?= josegonzalez/josegonzalez.github.io

.PHONY: all
all: remove-cache generate-data build

.PHONY: build
build:
	bundle exec jekyll build

.PHONY: server
server:
	bundle exec jekyll serve

.PHONY: dev-server
dev-server:
	bundle exec jekyll serve --limit_posts 1

.PHONY: remove-cache
remove-cache:
	rm -f bin/generate-data.cache.db

.PHONY: generate-data
generate-data:
	bin/generate-data

.PHONY: new-post
new-post:
ifndef POST_TITLE
	$(error POST_TITLE is undefined)
endif
	@bash -c \
		'TITLE=$$(echo $${POST_TITLE//[^[:alnum:]-]/-} | tr '[:upper:]' '[:lower:]' | tr -cs 'a-zA-Z0-9' '') ; \
		TITLE=$${TITLE%-} ; \
		POST_DATE=$$(date +"%Y-%m-%d") ; \
		POST_DATETIME=$$(date +"%Y-%m-%d %H:%M") ; \
		POST_FILENAME=_posts/$$POST_DATE-$$TITLE.markdown ; \
		cp _template.markdown $$POST_FILENAME ; \
		sed -i "" -e "s/POST_TITLE/$$POST_TITLE/g" $$POST_FILENAME ; \
		sed -i "" -e "s/POST_DESCRIPTION/$$POST_DESCRIPTION/g" $$POST_FILENAME ; \
		sed -i "" -e "s/POST_DATETIME/$$POST_DATETIME/g" $$POST_FILENAME ; \
		echo $$POST_FILENAME'

.PHONY: tags
tags:
	ls _site/tags

_site:
	git clone "git@github.com:${SITE_REPOSITORY}.git" _site

docker-build: _site
	docker run --rm \
	  --volume="$(PWD):/srv/jekyll" \
	  --volume="$(PWD)/vendor/bundle:/usr/local/bundle" \
	  -it jekyll/jekyll:$(shell cat Gemfile | grep jekyll | head -n1 | cut -d '"' -f4 | xargs -n1 | tail -n1) \
	  jekyll build
