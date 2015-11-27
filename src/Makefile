
COFFEE    := $(shell which coffee 2>/dev/null)
JSDUCKIFY := $(shell which jsduckify 2>/dev/null)
UGLIFYJS  := $(shell which uglifyjs 2>/dev/null)

Q ?= @
TARGET = app.js lib.js
RELEASE = $(TARGET:.js=.min.js)
RUNNER = node
DOCDIR = docs
SOURCES = \
	async.coffee \
	base.coffee \
	emscriptenrunner.coffee \
	port.coffee \
		serialport.coffee \
	memhttprequest.coffee \
	board.coffee \
		peridotboard.coffee \
		wakayamarbboard.coffee \
	editor.coffee \
		rubyeditor.coffee \
		yamleditor.coffee \
	fileutil.coffee \
	builder.coffee \
		mrubybuilder.coffee \
		mrbviewer.coffee \
	sketch.coffee \
	filesystem.coffee \
		localfilesystem.coffee \
		googledrivefilesystem.coffee \
	about.coffee \
#	marshal.coffee \
#	sandbox.coffee
#		de0board.coffee \
#		de0nanoboard.coffee \
#		wakayamarbboard.coffee \

LIB_SOURCES = \
	mruby/build/emscripten/bin/mrbc.js

EMLIB_EXPORTS := FS MEMFS EXITSTATUS

comma := ,
empty :=
space := $(empty) $(empty)

.PHONY: all
all: $(TARGET)

.PHONY: run
run: all
	@echo "[Running]"
	$(Q)$(RUNNER) $(RELEASE) $(LIB)

.PHONY: release
release: $(RELEASE)

.PHONY: clean
clean:
	@echo "[Cleaning]"
	$(Q)rm -f $(TARGET) $(RELEASE)

%.min.js: %.js $(firstword $(UGLIFYJS) uglifyjs-is-missing)
	@echo "[Minimizing $<]"
	$(Q)$(UGLIFYJS) -o $@ $< || (rm -f $@; false)

%.js: %.coffee $(firstword $(COFFEE) coffee-is-missing) $(MAKEFILE_LIST)
	@echo "[Compiling CoffeeScript files]"
	$(Q)coffee -c $< > $@ || (rm -f $@; false)

app.coffee: $(SOURCES) $(MAKEFILE_LIST)
	$(Q)cat /dev/null $(filter %.coffee,$^) > $@ || (rm -f $@; false)

lib.js: $(LIB_SOURCES) $(MAKEFILE_LIST)
	@echo "[Importing external libraries]"
	$(Q)echo "var Lib;Lib=(function(){function Lib(){}" > $@.tmp
	$(Q)true $(foreach f,$(filter %.js,$^), \
		&& echo "\
		Lib.$(notdir $(basename $(f)))=function(Module){\
		Module['preInit'] = Module['preInit'] || [];\
		Module['preInit'].unshift(function(){\
		Module['exports'] =\
		{$(subst $(space),$(comma),$(foreach e,$(EMLIB_EXPORTS),$(e):$(e)))};\
		});" >> $@.tmp \
		&& cat $(f) >> $@.tmp \
		&& echo "};" >> $@.tmp)
	$(Q)echo "return Lib;})();" >> $@.tmp
	$(Q)mv $@.tmp $@
#		&& echo "Module.exports={};" >> $@.tmp \
#		&& echo "Module.exports.fs=FS;" >> $@.tmp \

.PHONY: doc
doc: $(TARGET) $(firstword $(JSDUCKIFY) jsduckify-is-missing)
	@echo "[Generating document]"
	$(Q)$(JSDUCKIFY)

.PHONY: uglifyjs-is-missing
uglifyjs-is-missing:
	@echo "**** UglifyJS is required to build this project."
	@echo "**** Please visit https://github.com/mishoo/UglifyJS"
	@false

.PHONY: coffee-is-missing
coffee-is-missing:
	@echo "**** CoffeeScript is required to build this project."
	@echo "**** Please visit http://coffeescript.org/"
	@false

.PHONY: jsduckify-is-missing
jsduckify-is-missing:
	@echo "**** jsduckify is required to generate document for this project."
	@echo "**** Please visit https://github.com/lmaccherone/jsduckify"
	@false

DIST_DIR = ../dist

# Main files and mruby
DIST_FILES = manifest.json background.js window.html window.css $(TARGET)
# Embedded images
DIST_FILES += $(wildcard images/rubic_cube2x2_*.png) \
	images/mruby_logo_red_cropped.png \
	images/peridotcraft_logo_1.png \
	images/Emscripten_logo_full_cropped.png
# canarium
DIST_FILES += canarium.js
# jQuery
DIST_FILES += jquery-2.1.1.min.js
# Bootstrap (css, js and fonts)
DIST_FILES += $(addprefix bootstrap/dist/,css/bootstrap.min.css js/bootstrap.min.js)
DIST_FILES += $(addprefix bootstrap/dist/fonts/glyphicons-halflings-regular.,woff2)
# Ace (body and mode files)
DIST_FILES += $(addprefix ace-builds/src-noconflict/,ace.js mode-ruby.js mode-yaml.js mode-text.js theme-twilight.js)
# Bootstrap Notify
DIST_FILES += bootstrap-notify/dist/bootstrap-notify.min.js
# Bootbox.js
DIST_FILES += bootbox/bootbox.js
# js-yaml
DIST_FILES += js-yaml/dist/js-yaml.min.js
# spin.js
DIST_FILES += spin.min.js jquery.spin.js

DIST_INFO = $(DIST_DIR)/dist.txt

.PHONY: dist
dist: $(DIST_FILES)
	@echo "[Packing distribution files]"
	$(Q)test -z "$$(git status -uno --porcelain)" || \
		(echo "**** You must commit all files before distribution."; \
		 git status -uno; false)
	$(Q)mkdir -p $(DIST_DIR)
	$(Q)rm -rf $(DIST_DIR)/*
	$(Q)echo -n " " > $(DIST_INFO)
	$(Q)git log -1 --pretty=oneline >> $(DIST_INFO)
	$(Q)git submodule >> $(DIST_INFO)
	$(Q)cp --parent $^ $(DIST_DIR)
	$(Q)rm -f $(DIST_DIR)/../rubic.zip
	$(Q)cd $(DIST_DIR)/.. && zip -r rubic.zip $(notdir $(DIST_DIR))
	@echo "[Commits]"
	$(Q)cat $(DIST_INFO)

