NAME = santoku
VERSION = 0.0.21-1
GIT_URL = git@github.com:broma0/lua-santoku.git
HOMEPAGE = https://github.com/broma0/lua-santoku
LICENSE = MIT

BUILD_DIR = build

LUA = $(shell luarocks config lua_interpreter)

all:

include config/cli.mk
include config/lib.mk

upload: tag-version lib-upload cli-upload

tag-version:
	@if test -z "$(LUAROCKS_API_KEY)"; then echo "Missing LUAROCKS_API_KEY variable"; exit 1; fi
	@if ! git diff --quiet; then echo "Commit your changes first"; exit 1; fi
	git tag "$(VERSION)"
	git push --tags

clean:
	rm -rf "$(BUILD_DIR)"

.PHONY: all clean
