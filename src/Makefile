include ../common.mk

browserify_opts = --transform=coffeeify --extension=coffee --debug --full-paths

jsduck_opts = --external=ArrayBuffer,DirectoryEntry,Document,Element,Promise,jQuery

uglifyjs_opts = -c warnings=false

bkg_src  = $(SRC_DIR)/background.coffee
bkg_out  = $(DIST_DIR)/background.js
bkg_dep  = $(SRC_DIR)/.$(notdir $(bkg_src)).dep
bkg_min  = $(DIST_DIR)/background.min.js

top_src  = $(SRC_DIR)/top.coffee
top_out  = $(DIST_DIR)/window.js
top_dep  = $(SRC_DIR)/.$(notdir $(top_src)).dep
top_min  = $(DIST_DIR)/window.min.js

lib_src  = $(SRC_DIR)/library.coffee
lib_dep  = $(SRC_DIR)/.$(notdir $(lib_src)).dep
lib_min  = $(DIST_DIR)/library.min.js

stub_src = $(SRC_DIR)/stubs.coffee
stub_min = $(DIST_DIR)/stubs.min.js

mani_src = $(SRC_DIR)/manifest.json
mani_out = $(DIST_DIR)/$(notdir $(mani_src))

define update_dependency
	$(call ECHO_W,"Updating dependencies ($<)")
	$(Q)touch $@ && mv $@ $@~
	$(Q)echo "$@: \\" > $@
	$(Q)$(BROWSERIFY) $(browserify_opts) --list $< 2>/dev/null | sed -e 's/$$/ \\/' | sort >> $@ || (rm -f $@; false)
	$(Q)echo "$(filter-out %.dep,$(MAKEFILE_LIST))" >> $@
	$(Q)diff -u $@~ $@; rm $@~
endef

all: $(bkg_min) $(top_min) $(lib_min) $(stub_min) $(mani_out)

clean:
	$(Q)rm -f $(bkg_dep) $(bkg_dep)~ $(bkg_out)
	$(Q)rm -f $(top_dep) $(top_dep)~ $(top_out)
	$(Q)rm -f $(lib_dep) $(lib_dep)~ $(lib_min)
	$(Q)rm -f $(stub_min)
	$(Q)rm -f $(mani_out)

clobber: clean

$(bkg_out): $(bkg_dep) $(BROWSERIFY)
	$(call ECHO_W,"Compiling coffee scripts ($@)")
	$(Q)$(BROWSERIFY) $(browserify_opts) --outfile $@ $(bkg_src) || (rm -f $@ $(bkg_dep); false)

$(bkg_dep): $(bkg_src) $(BROWSERIFY)
	$(update_dependency)

$(bkg_min): $(bkg_out) $(UGLIFYJS)
	$(call ECHO_W,"Minimizing script ($@)")
	$(Q)$(UGLIFYJS) $(uglifyjs_opts) -o $@ $<

$(top_out): $(top_dep) $(BROWSERIFY)
	$(call ECHO_W,"Compiling coffee scripts ($@)")
	$(Q)$(BROWSERIFY) $(browserify_opts) --outfile $@ $(top_src) || (rm -f $@ $(top_dep); false)

$(top_dep): $(top_src) $(BROWSERIFY)
	$(update_dependency)

$(top_min): $(top_out) $(UGLIFYJS)
	$(call ECHO_W,"Minimizing script ($@)")
	$(Q)$(UGLIFYJS) $(uglifyjs_opts) -o $@ $<

$(lib_min): $(lib_dep) $(BROWSERIFY) $(ROOT_DIR)/package.json
	$(call ECHO_W,"Compiling coffee scripts ($@)")
	$(Q)$(BROWSERIFY) $(browserify_opts) $(lib_src) | $(UGLIFYJS) $(uglifyjs_opts) -o $@

$(lib_dep): $(lib_src) $(BROWSERIFY)
	$(update_dependency)

$(stub_min): $(stub_src) $(COFFEE) $(UGLIFYJS)
	$(call ECHO_W,"Generating stub scripts ($@)")
	$(Q)cat $< | $(COFFEE) -c -s | $(UGLIFYJS) $(uglifyjs_opts) -o $@

$(mani_out): $(mani_src) $(MAKEFILE_LIST)
	$(call ECHO_W,"Generating manifest ($@)")
	$(Q)sed -e 's/__BACKGROUND__/$(notdir $(bkg_min))/' $< > $@

.PHONY: doc
doc: $(top_out) $(JSDUCK)
	$(call ECHO_W,"Generating document ($@)")
	$(Q)$(JSDUCK) $(jsduck_opts) -o $@ $<

-include $(bkg_dep)
-include $(top_dep)
-include $(lib_dep)

