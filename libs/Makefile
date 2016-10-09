include ../common.mk

browserify_envs =

browserify_opts = \
	--transform=coffeeify --extension=coffee --debug \
	$(addprefix --external=,crypto serialport)

node_src  = $(LIBS_DIR)/nodemodules.coffee
node_min  = $(DIST_DIR)/nodemodules.min.js

em_runner = emscriptenrunner.coffee

mrbc_name = mrbc
mrbc_src  = mruby/build/emscripten/bin/mrbc.js
mrbc_mem  = $(mrbc_src).mem
mrbc_sout = $(DIST_DIR)/$(notdir $(mrbc_src))
mrbc_mout = $(DIST_DIR)/$(notdir $(mrbc_mem))

define em_build
	$(call ECHO_W,"Generating emscripten module ($($1_name))")
	$(Q)mkdir -p $(dir $@)
	$(Q)echo "(function(){function $($1_name)(){" > $@
	$(Q)cat $(em_runner) | $(COFFEE) -bcs | $(UGLIFYJS) >> $@
	$(Q)cat $< >> $@
	$(Q)echo "return}(this.Libs=(this.Libs||{})).$($1_name)=$($1_name)})()" >> $@
endef

all: $(node_min) $(mrbc_sout) $(mrbc_mout)

release: all

clean:
	$(Q)rm -f $(node_min)
	$(Q)rm -f $(mrbc_sout) $(mrbc_mout)

clobber: clean
	$(Q)$(MAKE) -C mruby clean

$(node_min): $(node_src) $(BROWSERIFY) $(ROOT_DIR)/package.json
	$(call ECHO_W,"Updating npm packages")
	$(Q)cd $(ROOT_DIR) && npm install
	$(call ECHO_W,"Gathering node modules ($@)")
	$(Q)$(browserify_envs) $(BROWSERIFY) $(browserify_opts) $< | $(UGLIFYJS) $(uglifyjs_opts) > $@ || (rm -f $@; false)

$(mrbc_src): $(EMCC)
	$(call ECHO_W,"Building mruby")
	$(Q)$(MAKE) -C mruby

$(mrbc_sout): $(mrbc_src) $(em_runner) $(MAKEFILE_LIST)
	$(call em_build,mrbc)

$(mrbc_mout): $(mrbc_mem)
	$(Q)mkdir -p $(dir $@)
	$(Q)cp $< $@

