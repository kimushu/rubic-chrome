
COFFEE := $(shell which coffee 2>/dev/null)

Q ?= @
TARGET = app.js
RUNNER = node
SOURCES = \
	common.coffee \
	serial.coffee \
	editor.coffee \
		rubyeditor.coffee \
	board.coffee \
		peridotboard.coffee \
		de0board.coffee \
		de0nanoboard.coffee \
	builder.coffee \
		mrubybuilder.coffee \
	sketch.coffee \
	sandbox.coffee

all:

.PHONY: run
run: all
	@echo "[Running]"
	$(Q)$(RUNNER) $(TARGET)

.PHONY: all
all: app.js

$(TARGET): $(SOURCES:.coffee=.js)
	@echo "[Generating $@]"
	$(Q)cat $^ > $@ || (rm -f $@; false)

.PHONY: clean
clean:
	@echo "[Cleaning]"
	$(Q)rm -f $(TARGET) $(SOURCES:.coffee=.js)

.PHONY: coffee-is-required
coffee-is-required:
	@echo "**** CoffeeScript is required to compile this project."
	@echo "**** Please visit http://coffeescript.org/"
	@false

%.js: %.coffee $(firstword $(COFFEE) coffee-is-required) $(MAKEFILE_LIST)
	@echo "[Compiling $<]"
	$(Q)$(COFFEE) --bare --compile $<

