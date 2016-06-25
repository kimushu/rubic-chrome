include ../common.mk

browserify_opts =

em_runner = emscriptenrunner.coffee

mrbc_name = mrbc
mrbc_src  = mruby/build/emscripten/bin/mrbc.js
mrbc_mem  = $(mrbc_src).mem
mrbc_sout = $(DIST_DIR)/$(notdir $(mrbc_src))
mrbc_mout = $(DIST_DIR)/$(notdir $(mrbc_mem))

define em_build
	$(call ECHO_W,"Generating emscripten module ($($1_name))")
	$(Q)mkdir -p $(dir $@)
	$(Q)echo "function $($1_name)(){" > $@
	$(Q)cat $(em_runner) | $(COFFEE) -bcs | $(UGLIFYJS) >> $@
	$(Q)cat $< >> $@
	$(Q)echo "return;}" >> $@
endef

all: $(mrbc_sout) $(mrbc_mout)

clean:
	$(Q)rm -f $(mrbc_sout) $(mrbc_mout)

clobber: clean
	$(Q)$(MAKE) -C mruby clean

$(mrbc_src): $(EMCC)
	$(call ECHO_W,"Building mruby")
	$(Q)$(MAKE) -C mruby

$(mrbc_sout): $(mrbc_src) $(em_runner) $(MAKEFILE_LIST)
	$(call em_build,mrbc)

$(mrbc_mout): $(mrbc_mem)
	$(Q)mkdir -p $(dir $@)
	$(Q)cp $< $@

