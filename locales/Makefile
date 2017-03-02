include ../common.mk

langs = ja en

out_dir = $(DIST_DIR)/_locales
out_file = $(out_dir)/$1/messages.json
messages = $(foreach l,$(langs),$(call out_file,$(l)))
converter = yaml2json.rb

tester_src = $(LOCALE_DIR)/tester.coffee
tester_out = $(DIST_DIR)/locale.js

all: $(messages)

release: $(tester_out)

.PHONY: $(tester_out)
$(tester_out):
	$(Q)echo "/* chrome.i18n */" > $@

tester-%: $(call out_file,%) $(COFFEE) $(MAKEFILE_LIST)
	$(call ECHO_Y,"Generating tester script for $*")
	$(Q)echo -n "L = \"$*\"; M = " | cat - $< $(tester_src) | \
		$(COFFEE) -s -c > $(tester_out) || (rm -f $@; false)

clean:
	$(call ECHO_Y,"Cleaning locale files...")
	$(Q)rm -f $(tester_out)
	$(Q)rm -rf $(out_dir)

clobber: clean

$(call out_file,%): %.yaml $(converter) $(MAKEFILE_LIST)
	$(call ECHO_W,"Generating translated messages for locale '$*'")
	$(Q)mkdir -p $(dir $@)
	$(Q)ruby $(converter) $< > $@ || (rm -f $@; false)

