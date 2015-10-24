#----------------------------------------------------------------
# Makefile for Rubic
#----------------------------------------------------------------

# Compilers and tools
COFFEE   := $(shell which coffee 2>/dev/null)
JSDUCK   := $(shell which jsduck 2>/dev/null)
UGLIFYJS := $(shell which uglifyjs 2>/dev/null)

# Make options
Q ?= @

# Output directories
JS_DIR  = js
DOC_DIR = ../doc
REL_DIR = ../dist

# Source files
SOURCES = \
	launcher.coffee \
	common.coffee \
	eventtarget.coffee \
	i18n.coffee \
	app.coffee \
	windowcontroller.coffee \
		maincontroller.coffee \
		catalogcontroller.coffee \
	sketch.coffee \
	fileutil.coffee \
	editor.coffee \
		sketcheditor.coffee \
		texteditor.coffee \
			rubyeditor.coffee \
			coffeescripteditor.coffee \
	emscriptenrunner.coffee \
	builder.coffee \
		mrubybuilder.coffee \
		coffeescriptbuilder.coffee \
#	board.coffee \
#		peridotboard.coffee \
#			javascripteditor.coffee \
#			coffeescripteditor.coffee \
#	utils.coffee \
#	async.coffee \
#	app.coffee \
#	port.coffee \
#		serialport.coffee \
#	memhttprequest.coffee \
#		wakayamarbboard.coffee \
#			yamleditor.coffee \
#			mrbviewer.coffee \
	hardwarecatalog.coffee \
	hardware.coffee \
#		pythonbuilder.coffee \
#		javascriptbuilder.coffee \
#	githubrepofilesystem.coffee \
#	about.coffee \
#	localfilesystem.coffee \
#	googledrivefilesystem.coffee \
#	marshal.coffee \
#	sandbox.coffee
#		de0board.coffee \
#		de0nanoboard.coffee \

# JS libraries
LIBS = \
	mruby/build/emscripten/bin/mrbc.js

# Combined library file
TARGET_LIB = lib.js

TARGETS = \
	$(foreach s,$(SOURCES),$(JS_DIR)/$(s:.coffee=.js)) \
	$(TARGET_LIB) \
	manifest.json

BKG_SOURCES = \
	app.coffee \
	windowcontroller.coffee \
		maincontroller.coffee \

EMLIB_EXPORTS := FS MEMFS EXITSTATUS

comma := ,
empty :=
space := $(empty) $(empty)

EXTERNAL_CLASSES = \
	AppWindow \
	ArrayBuffer \
	Canarium \
	DOMElement \
	DirectoryEntry \
	FileEntry \
	ace.EditSession \
	ace.Editor \
	jQuery \

RELEASE_DIR = ../dist

build:

.PHONY: build
build: $(TARGETS)

.PHONY: release
release: $(TARGET_RELEASE)

.PHONY: clean
clean:
	@echo "[Cleaning]"
	$(Q)rm -f $(TARGETS)

# %.min.js: %.js $(firstword $(UGLIFYJS) uglifyjs-is-missing)
# 	@echo "[Minimizing $<]"
# 	$(Q)$(UGLIFYJS) -o $@ $< || (rm -f $@; false)

$(JS_DIR):
	$(Q)mkdir -p $@

$(JS_DIR)/%.js: %.coffee $(JS_DIR) $(firstword $(COFFEE) coffee-is-missing) $(MAKEFILE_LIST)
	@echo "[Compiling $<]"
	$(Q)$(COFFEE) -c -m -o $(JS_DIR) $< || (rm -f $@; false)

manifest.json: manifest.head $(MAKEFILE_LIST) manifest.tail
	@echo "[Generating $@]"
	$(Q)cat $(firstword $^) > $@
	$(Q)true $(foreach s,$(SOURCES),&& echo "        \"$(JS_DIR)/$(s:.coffee=.js)\"," >> $@)
	$(Q)cat $(lastword $^) >> $@ || (rm -f $@; false)

lib.js: $(LIBS) $(MAKEFILE_LIST)
	@echo "[Importing external libraries]"
	$(Q)echo "Rubic.Lib=(function(){function Lib(){}" > $@.tmp
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

background.coffee: $(BKG_SOURCES) $(MAKEFILE_LIST)
	$(Q)cat /dev/null $(filter %.coffee,$^) > $@ || (rm -f $@; false)

.PHONY: doc
doc: $(TARGETS) $(firstword $(JSDUCK) jsduckify-is-missing)
	@echo "[Generating document]"
	$(Q)$(JSDUCK) \
		-o $(DOC_DIR) \
		--external=$(subst $(space),$(comma),$(EXTERNAL_CLASSES)) \
		$(filter $(JS_DIR)/%.js,$^)

.PHONY: coffee-is-missing
coffee-is-missing:
	@echo "**** CoffeeScript is required to build this project."
	@echo "**** Please visit http://coffeescript.org/"
	@false

.PHONY: jsduck-is-missing
jsduck-is-missing:
	@echo "**** JSDuck is required to generate document for this project."
	@echo "**** Please visit https://github.com/senchalabs/jsduck"
	@false

.PHONY: uglifyjs-is-missing
uglifyjs-is-missing:
	@echo "**** UglifyJS is required to release this project."
	@echo "**** Please visit https://github.com/mishoo/UglifyJS"
	@false

DIST_DIR = ../dist

# Main files and mruby
DIST_FILES = manifest.json win_main.html win_main.css win_catalog.html win_catalog.css $(TARGET)
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
DIST_FILES += $(addprefix bootstrap/,css/bootstrap.min.css js/bootstrap.min.js)
DIST_FILES += $(addprefix bootstrap/fonts/glyphicons-halflings-regular.,woff2)
# Ace (body and mode files)
DIST_FILES += $(addprefix ace-builds/src-noconflict/,ace.js mode-ruby.js mode-yaml.js)
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

