
Q ?= @

ROOT_DIR   := $(patsubst %/,%,$(dir $(lastword $(MAKEFILE_LIST))))
DIST_DIR   := $(ROOT_DIR)/dist
SRC_DIR    := $(ROOT_DIR)/src
LIBS_DIR   := $(ROOT_DIR)/libs
VIEW_DIR   := $(ROOT_DIR)/view
LOCALE_DIR := $(ROOT_DIR)/locale
TEST_DIR   := $(ROOT_DIR)/test

NPM_BIN    := $(shell npm bin)

BROWSERIFY := $(NPM_BIN)/browserify
COFFEE     := $(NPM_BIN)/coffee
UGLIFYJS   := $(NPM_BIN)/uglifyjs
LESSC      := $(NPM_BIN)/lessc
JSDUCK     := $(firstword $(shell which jsduck 2> /dev/null) .jsduck-required)
EMCC       := $(firstword $(shell which emcc 2> /dev/null) .emscripten-required)

ECHO_R     = @echo -e "\033[1;31m\# "$1"\033[0m"
ECHO_G     = @echo -e "\033[1;32m\# "$1"\033[0m"
ECHO_Y     = @echo -e "\033[1;33m\# "$1"\033[0m"
ECHO_B     = @echo -e "\033[1;34m\# "$1"\033[0m"
ECHO_M     = @echo -e "\033[1;35m\# "$1"\033[0m"
ECHO_C     = @echo -e "\033[1;36m\# "$1"\033[0m"
ECHO_W     = @echo -e "\033[1;37m\# "$1"\033[0m"

TEST0      = test $${PIPESTATUS[0]} -eq 0
TEST0_RM   = $(TEST0) || (rm -f $@; false)

.PHONY: all clean clobber
all:
	$(call ECHO_B,"Build finished for target \`$@'")

$(BROWSERIFY) $(COFFEE) $(UGLIFYJS) $(LESSC):
	$(call ECHO_C,"Installing npm packages")
	$(Q)cd $(ROOT_DIR) && npm install

$(JSDUCK):
	$(call ECHO_C,"Installing gem packages")
	$(Q)cd $(ROOT_DIR) && bundle install

$(EMCC):
	$(call ECHO_R,"Emscripten (emcc) not found!")
	$(call ECHO_R,"Please install manually: http://emscripten.org/")
	@false

clean: clean-message

.PHONY: clean-message
clean-message:
	$(call ECHO_Y,"Cleaning files")

clobber: clobber-message

.PHONY: clobber-message
clobber-message:
	$(call ECHO_M,"Clobbering files")

