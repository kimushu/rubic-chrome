include ../common.mk

browserify_opts = --transform=coffeeify --extension=coffee --debug

jsduck_opts = --external=ArrayBuffer,DirectoryEntry,Document,Element,Promise,jQuery

uglifyjs_opts = -c warnings=false

bkg_src = $(SRC_DIR)/background.coffee
bkg_out = $(DIST_DIR)/background.js
bkg_dep = $(SRC_DIR)/.$(notdir $(bkg_src)).dep
bkg_min = $(DIST_DIR)/background.min.js

top_src = $(SRC_DIR)/top.coffee
top_out = $(DIST_DIR)/window.js
top_dep = $(SRC_DIR)/.$(notdir $(top_src)).dep
top_min = $(DIST_DIR)/window.min.js

lib_src = $(SRC_DIR)/library.coffee
lib_dep = $(SRC_DIR)/.$(notdir $(lib_src)).dep
lib_min = $(DIST_DIR)/library.min.js

all: $(bkg_min) $(top_min) $(lib_min)

$(bkg_out): $(bkg_dep) $(BROWSERIFY)
	$(call ECHO_W,"Compiling coffee scripts ($@)")
	$(Q)$(BROWSERIFY) $(browserify_opts) --outfile $@ $(bkg_src) || (rm -f $@ $(bkg_dep); false)

$(bkg_dep): $(bkg_src) $(BROWSERIFY)
	$(call ECHO_W,"Updating dependencies ($<)")
	$(Q)echo "$@: \\" > $@
	$(Q)$(BROWSERIFY) $(browserify_opts) --list $< 2>/dev/null | sed -e 's/$$/ \\/' >> $@ || (rm -f $@; false)
	$(Q)echo "$(filter-out %.dep,$(MAKEFILE_LIST))" >> $@

$(bkg_min): $(bkg_out) $(UGLIFYJS)
	$(call ECHO_W,"Minimizing script ($@)")
	$(Q)$(UGLIFYJS) $(uglifyjs_opts) -o $@ $<

$(top_out): $(top_dep) $(BROWSERIFY)
	$(call ECHO_W,"Compiling coffee scripts ($@)")
	$(Q)$(BROWSERIFY) $(browserify_opts) --outfile $@ $(top_src) || (rm -f $@ $(top_dep); false)

$(top_dep): $(top_src) $(BROWSERIFY)
	$(call ECHO_W,"Updating dependencies ($<)")
	$(Q)echo "$@: \\" > $@
	$(Q)$(BROWSERIFY) $(browserify_opts) --list $< 2>/dev/null | sed -e 's/$$/ \\/' >> $@ || (rm -f $@; false)
	$(Q)echo "$(filter-out %.dep,$(MAKEFILE_LIST))" >> $@

$(top_min): $(top_out) $(UGLIFYJS)
	$(call ECHO_W,"Minimizing script ($@)")
	$(Q)$(UGLIFYJS) $(uglifyjs_opts) -o $@ $<

$(lib_min): $(lib_dep) $(BROWSERIFY) $(ROOT_DIR)/package.json
	$(call ECHO_W,"Compiling coffee scripts ($@)")
	$(Q)$(BROWSERIFY) $(browserify_opts) $(lib_src) | $(UGLIFYJS) $(uglifyjs_opts) -o $@

$(lib_dep): $(lib_src) $(BROWSERIFY)
	$(call ECHO_W,"Updating dependencies ($<)")
	$(Q)echo "$@: \\" > $@
	$(Q)$(BROWSERIFY) $(browserify_opts) --list $< 2>/dev/null | sed -e 's/$$/ \\/' >> $@ || (rm -f $@; false)
	$(Q)echo "$(filter-out %.dep,$(MAKEFILE_LIST))" >> $@

clean:
	$(call ECHO_Y,"Cleaning files")
	$(Q)rm -f $(top_dep) $(top_out)

clobber: clean

-include $(bkg_dep)

-include $(top_dep)

