
Q ?= @

ROOT_DIR   := $(patsubst %/,%,$(dir $(lastword $(MAKEFILE_LIST))))
DIST_DIR   := $(ROOT_DIR)/dist
SRC_DIR    := $(ROOT_DIR)/src
VIEW_DIR   := $(ROOT_DIR)/view
LOCALE_DIR := $(ROOT_DIR)/locale
TEST_DIR   := $(ROOT_DIR)/test

NPM_DIR    := $(shell npm bin)

BROWSERIFY := $(NPM_DIR)/browserify
COFFEE     := $(NPM_DIR)/coffee
UGLIFYJS   := $(NPM_DIR)/uglifyjs
LESSC      := $(NPM_DIR)/lessc
JSDUCK     := $(firstword $(shell which jsduck 2> /dev/null) .jsduck-required)

ECHO_R     = @echo -e "\033[1;31m\# "$1"\033[0m"
ECHO_G     = @echo -e "\033[1;32m\# "$1"\033[0m"
ECHO_Y     = @echo -e "\033[1;33m\# "$1"\033[0m"
ECHO_B     = @echo -e "\033[1;34m\# "$1"\033[0m"
ECHO_M     = @echo -e "\033[1;35m\# "$1"\033[0m"
ECHO_C     = @echo -e "\033[1;36m\# "$1"\033[0m"
ECHO_W     = @echo -e "\033[1;37m\# "$1"\033[0m"

.PHONY: all clean clobber
all:

$(BROWSERIFY) $(COFFEE) $(UGLIFYJS) $(LESSC):
	@echo "Installing npm packages"
	$(Q)cd $(ROOT_DIR) && npm install

$(JSDUCK):
	@echo "Installing gem packages"
	$Q()cd $(ROOT_DIR) && bundle install

