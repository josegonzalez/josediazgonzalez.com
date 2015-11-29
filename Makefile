.PHONY: all
all: remove-cache generate-data build

.PHONY: build
build:
	jekyll build

.PHONY: remove-cache
remove-cache:
	rm -f bin/generate-data.cache.db

.PHONY: generate-data
generate-data:
	bin/generate-data
