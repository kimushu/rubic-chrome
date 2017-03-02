build start watch:
	$(MAKE) -C .. $@

include ../common.mk

browserify_envs = NODE_PATH=$(SRC_DIR)

browserify_opts = \
	--transform=coffeeify --extension=coffee --debug \
	$(addprefix --external=,crypto serialport)

jsduck_opts = --external=ArrayBuffer,DirectoryEntry,Document,Element,Promise,jQuery

uglifyjs_opts = -c warnings=false

dep      = $(dir $1)/.$(notdir $1).dep

bkg_src  = $(SRC_DIR)/background.coffee
bkg_out  = $(DIST_DIR)/background.js
bkg_dep  = $(call dep,$(bkg_src))
bkg_min  = $(DIST_DIR)/background.min.js

top_src  = $(SRC_DIR)/top.coffee
top_out  = $(DIST_DIR)/window.js
top_dep  = $(call dep,$(top_src))
top_min  = $(DIST_DIR)/window.min.js

stub_src = $(SRC_DIR)/stubs.coffee
stub_min = $(DIST_DIR)/stubs.min.js

mani_src = $(SRC_DIR)/manifest.json
mani_out = $(DIST_DIR)/$(notdir $(mani_src))

define compile_coffee
	$(call ECHO_W,"Compiling coffee scripts ($@)")
	$(Q)echo "$@: \\" > $(call dep,$<).new
	$(Q)$(browserify_envs) $(BROWSERIFY) $(browserify_opts) --list $< | \
		sort | sed -e 's/$$/ \\/' >> $(call dep,$<).new; \
		$(TEST0) || (rm -f $(call dep,$<).new; false)
	$(Q)echo "$(filter-out %.dep,$(MAKEFILE_LIST))" >> $(call dep,$<).new
	$(Q)touch $(call dep,$<)
	$(Q)diff -u $(call dep,$<) $(call dep,$<).new; true
	$(Q)mv $(call dep,$<).new $(call dep,$<)
	$(Q)mkdir -p $(dir $@)
	$(Q)$(browserify_envs) $(BROWSERIFY) $(browserify_opts) $< $1 > $@ || (rm -f $@; false)
endef

all: $(bkg_min) $(top_out) $(stub_min) $(mani_out)

release: all $(top_min)

clean:
	$(Q)rm -f $(bkg_dep) $(bkg_dep).new $(bkg_out)
	$(Q)rm -f $(top_dep) $(top_dep).new $(top_out)
	$(Q)rm -f $(stub_min)
	$(Q)rm -f $(mani_out)

clobber: clean

$(bkg_out): $(bkg_src) $(BROWSERIFY)
	$(call compile_coffee)

$(bkg_min): $(bkg_out) $(UGLIFYJS)
	$(call ECHO_W,"Minimizing script ($@)")
	$(Q)$(UGLIFYJS) $(uglifyjs_opts) -o $@ $<

$(top_out): $(top_src) $(BROWSERIFY)
	$(call compile_coffee)

$(top_min): $(top_out) $(UGLIFYJS)
	$(call ECHO_W,"Minimizing script ($@)")
	$(Q)$(UGLIFYJS) $(uglifyjs_opts) -o $@ $<

$(stub_min): $(stub_src) $(COFFEE) $(UGLIFYJS)
	$(call ECHO_W,"Generating stub scripts ($@)")
	$(Q)mkdir -p $(dir $@)
	$(Q)cat $< | $(COFFEE) -c -s | $(UGLIFYJS) $(uglifyjs_opts) -o $@

$(mani_out): $(mani_src) $(MAKEFILE_LIST)
	$(call ECHO_W,"Generating manifest ($@)")
	$(Q)mkdir -p $(dir $@)
	$(Q)sed -e 's/__BACKGROUND__/$(notdir $(bkg_min))/' $< > $@

.PHONY: doc
doc: $(top_out) $(JSDUCK)
	$(call ECHO_W,"Generating document ($@)")
	$(Q)$(JSDUCK) $(jsduck_opts) -o $@ $<

-include $(bkg_dep)
-include $(top_dep)

