include ../common.mk

all: html
clean: clean-html
clobber: clobber-html

dwld_dir  = $(VIEW_DIR)/downloads

#--------------------------------------------------------------------------------
# HTML generation
#

html_gen  = $(VIEW_DIR)/generate_html.rb
html_src  = $(VIEW_DIR)/main.html
html_out  = $(DIST_DIR)/window.html
html_dep  = $(VIEW_DIR)/.$(notdir $(html_src)).dep

.PHONY: html
html: $(html_out) css jquery twbs fawe ace

$(html_out): $(html_gen) $(MAKEFILE_LIST)
	$(call ECHO_W,"Generating HTML ($@)")
	$(Q)mkdir -p $(dir $@)
	$(Q)ruby $< -d $(html_dep) -v -s $(html_src) $@

-include $(html_dep)

.PHONY: clean-html
clean-html: clean-css clean-jquery clean-twbs clean-fawe clean-ace
	$(Q)rm -f $(html_out)

.PHONY: clobber-html
clobber-html: clean-html
clobber-html: clobber-css clobber-jquery clobber-twbs clobber-fawe clobber-ace

#--------------------------------------------------------------------------------
# Twitter Bootstrap
#

twbs_ver  = 3.3.4
twbs_dir  = $(dwld_dir)/bootstrap-$(twbs_ver)
twbs_tgz  = $(twbs_dir).tar.gz
twbs_key  = $(twbs_dir)/README.md
twbs_url  = https://github.com/twbs/bootstrap/archive/v$(twbs_ver).tar.gz
twbs_fsrc = $(twbs_dir)/dist/fonts/glyphicons-halflings-regular.woff2
twbs_jsrc = $(twbs_dir)/dist/js/bootstrap.min.js
twbs_fout = $(DIST_DIR)/fonts/$(notdir $(twbs_fsrc))
twbs_jout = $(DIST_DIR)/$(notdir $(twbs_jsrc))

.PHONY: twbs
twbs: $(twbs_fout) $(twbs_jout) $(twbs_key)

$(twbs_fout): $(twbs_key)
	$(call ECHO_W,"Locating bootstrap font ($@)")
	$(Q)mkdir -p $(dir $@) && cp $(twbs_fsrc) $@

$(twbs_jout): $(twbs_key)
	$(call ECHO_W,"Locating bootstrap script ($@)")
	$(Q)mkdir -p $(dir $@) && cp $(twbs_jsrc) $@

$(twbs_key): $(twbs_tgz)
	$(call ECHO_W,"Unpacking bootstrap tarball ($<)")
	$(Q)tar -C $(dir $<) -xf $< && touch $@

$(twbs_tgz):
	$(call ECHO_C,"Downloading bootstrap tarball ($(twbs_url))")
	$(Q)mkdir -p $(dir $@) && curl -L -o $@ "$(twbs_url)"

.PHONY: clean-twbs
clean-twbs:
	$(Q)rm -f $(twbs_fout) $(twbs_jout)

.PHONY: clobber-twbs
clobber-twbs: clean-twbs
	$(Q)rm -rf $(twbs_dir)
	$(Q)rm -f $(twbs_tgz)

#--------------------------------------------------------------------------------
# CSS generation (from less)
#

css_src   = $(VIEW_DIR)/window.less
css_out   = $(DIST_DIR)/css/window.css
css_link  = $(VIEW_DIR)/css/window.css

lessc_opts = --no-ie-compat --clean-css --include-path=$(dwld_dir)

.PHONY: css
css: $(css_out) $(css_link)

$(css_out): $(css_src) $(twbs_key) $(firstword $(lessc)) $(MAKEFILE_LIST)
	$(call ECHO_W,"Compiling CSS ($@)")
	$(Q)mkdir -p $(dir $@)
	$(Q)$(LESSC) $(lessc_opts) $< > $@ || (rm -f $@; false)

$(css_link): $(css_out)
	$(Q)mkdir -p $(dir $@) && ln -sr $< $@

.PHONY: clean-css
clean-css: clean-twbs
	$(Q)rm -f $(css_out) $(css_link)

.PHONY: clobber-css
clobber-css: clean-css

#--------------------------------------------------------------------------------
# jQuery
#

jqy_ver   = 2.2.4
jqy_url   = https://code.jquery.com/jquery-$(jqy_ver).min.js
jqy_src   = $(dwld_dir)/$(notdir $(jqy_url))
jqy_out   = $(DIST_DIR)/$(notdir $(jqy_src))

.PHONY: jquery
jquery: $(jqy_out)

$(jqy_out): $(jqy_src)
	$(call ECHO_W,"Locating jQuery script ($@)")
	$(Q)cp $< $@

$(jqy_src):
	$(call ECHO_C,"Downloading jQuery source ($(jqy_url))")
	$(Q)mkdir -p $(dir $@) && curl -L -o $@ "$(jqy_url)"

.PHONY: clean-jquery
clean-jquery:
	$(Q)rm -f $(jqy_out)

.PHONY: clobber-jquery
clobber-jquery: clean-jquery
	$(Q)rm -f $(jqy_src)

#--------------------------------------------------------------------------------
# font awesome
#

fawe_ver  = 4.6.3
fawe_dir  = $(dwld_dir)/Font-Awesome-$(fawe_ver)
fawe_tgz  = $(fawe_dir).tar.gz
fawe_key  = $(fawe_dir)/README.md
fawe_url  = https://github.com/FortAwesome/Font-Awesome/archive/v$(fawe_ver).tar.gz
fawe_csrc = $(fawe_dir)/css/font-awesome.min.css
fawe_fsrc = $(fawe_dir)/fonts/fontawesome-webfont.woff2
fawe_cout = $(DIST_DIR)/css/$(notdir $(fawe_csrc))
fawe_fout = $(DIST_DIR)/fonts/$(notdir $(fawe_fsrc))

.PHONY: fawe
fawe: $(fawe_cout) $(fawe_fout)

$(fawe_cout): $(fawe_key)
	$(call ECHO_W,"Locating font-awesome css ($@)")
	$(Q)mkdir -p $(dir $@) && cp $(fawe_csrc) $@

$(fawe_fout): $(fawe_key)
	$(call ECHO_W,"Locating font-awesome font ($@)")
	$(Q)mkdir -p $(dir $@) && cp $(fawe_fsrc) $@

$(fawe_key): $(fawe_tgz)
	$(call ECHO_W,"Unpacking font-awesome tarball ($<)")
	$(Q)tar -C $(dir $<) -xf $< && touch $@

$(fawe_tgz):
	$(call ECHO_C,"Downloading font-awesome tarball ($(fawe_url))")
	$(Q)mkdir -p $(dir $@) && curl -L -o $@ "$(fawe_url)"

.PHONY: clean-fawe
clean-fawe:
	$(Q)rm -f $(fawe_cout) $(fawe_fout)

.PHONY: clobber-fawe
clobber-fawe: clean-fawe
	$(Q)rm -rf $(fawe_dir)
	$(Q)rm -f $(fawe_tgz)

#--------------------------------------------------------------------------------
# Ace
#

ace_ver   = 1.2.3
ace_url   = https://github.com/ajaxorg/ace-builds/archive/v$(ace_ver).tar.gz
ace_dir   = $(dwld_dir)/ace-builds-$(ace_ver)
ace_tgz   = $(ace_dir).tar.gz
ace_key   = $(ace_dir)/README.md
ace_src   = $(ace_dir)/src-min-noconflict
ace_out   = $(DIST_DIR)/ace

.PHONY: ace
ace: $(ace_out)

$(ace_out): $(ace_key)
	$(call ECHO_W,"Locating Ace scripts ($@)")
	$(Q)mkdir -p $(dir $@) && cp -r $(ace_src) $(ace_out)

$(ace_key): $(ace_tgz)
	$(call ECHO_W,"Unpacking Ace tarball ($<)")
	$(Q)tar -C $(dir $<) -xf $< && touch $@

$(ace_tgz):
	$(call ECHO_C,"Downloading Ace tarball ($(ace_url))")
	$(Q)mkdir -p $(dir $@) && curl -L -o $@ "$(ace_url)"

.PHONY: clean-ace
clean-ace:
	$(Q)rm -rf $(ace_out)

.PHONY: clobber-ace
clobber-ace: clean-ace
	$(Q)rm -rf $(ace_dir)
	$(Q)rm -f $(ace_tgz)

