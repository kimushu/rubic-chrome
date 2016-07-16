include ../common.mk

all: html
clean: clean-html
clobber: clobber-html

dwld_dir  = $(VIEW_DIR)/downloads
modules   = jqy twbs fawe ace spin jqsp bbox jqst cana jstr

.PHONY: info
info:
	$(call ECHO_W,"Module versions")
	@true $(foreach m,$(modules),&& printf "    %-14s : %s\n" "$($(m)_name)" "$($(m)_ver)")

#--------------------------------------------------------------------------------
# jQuery
#

jqy_name  = jQuery
jqy_ver   = 2.2.4
jqy_url   = https://code.jquery.com/jquery-$(jqy_ver).min.js
jqy_src   = $(dwld_dir)/$(notdir $(jqy_url))
jqy_out   = $(DIST_DIR)/$(notdir $(jqy_src))

.PHONY: jqy clean-jqy clobber-jqy
jqy: $(jqy_out)

clean-jqy:
	$(Q)rm -f $(jqy_out)

clobber-jqy: clean-jqy
	$(Q)rm -f $(jqy_src)

$(jqy_out): $(jqy_src)
	$(call ECHO_W,"Locating $(jqy_name) script ($@)")
	$(Q)mkdir -p $(dir $@) && cp $< $@

$(jqy_src):
	$(call ECHO_C,"Downloading $(jqy_name) source ($(jqy_url))")
	$(Q)mkdir -p $(dir $@) && curl -L -o $@ "$(jqy_url)"

#--------------------------------------------------------------------------------
# Twitter Bootstrap
#

twbs_name = Bootstrap
twbs_ver  = 3.3.4
twbs_dir  = $(dwld_dir)/bootstrap-$(twbs_ver)
twbs_tgz  = $(twbs_dir).tar.gz
twbs_key  = $(twbs_dir)/.unpacked
twbs_url  = https://github.com/twbs/bootstrap/archive/v$(twbs_ver).tar.gz
twbs_fsrc = $(twbs_dir)/dist/fonts/glyphicons-halflings-regular.woff2
twbs_jsrc = $(twbs_dir)/dist/js/bootstrap.min.js
twbs_fout = $(DIST_DIR)/fonts/$(notdir $(twbs_fsrc))
twbs_jout = $(DIST_DIR)/$(notdir $(twbs_jsrc))

.PHONY: twbs clean-twbs clobber-twbs
twbs: $(twbs_fout) $(twbs_jout) $(twbs_key)

clean-twbs:
	$(Q)rm -f $(twbs_fout) $(twbs_jout)

clobber-twbs: clean-twbs
	$(Q)rm -rf $(twbs_dir)
	$(Q)rm -f $(twbs_tgz)

$(twbs_fout): $(twbs_key)
	$(call ECHO_W,"Locating $(twbs_name) font ($@)")
	$(Q)mkdir -p $(dir $@) && cp $(twbs_fsrc) $@

$(twbs_jout): $(twbs_key)
	$(call ECHO_W,"Locating $(twbs_name) script ($@)")
	$(Q)mkdir -p $(dir $@) && cp $(twbs_jsrc) $@

$(twbs_key): $(twbs_tgz)
	$(call ECHO_W,"Unpacking $(twbs_name) tarball ($<)")
	$(Q)tar -C $(dir $<) -xf $< && touch $@

$(twbs_tgz):
	$(call ECHO_C,"Downloading $(twbs_name) tarball ($(twbs_url))")
	$(Q)mkdir -p $(dir $@) && curl -L -o $@ "$(twbs_url)"

#--------------------------------------------------------------------------------
# font awesome
#

fawe_name = Font Awesome
fawe_ver  = 4.6.3
fawe_dir  = $(dwld_dir)/Font-Awesome-$(fawe_ver)
fawe_tgz  = $(fawe_dir).tar.gz
fawe_key  = $(fawe_dir)/.unpacked
fawe_url  = https://github.com/FortAwesome/Font-Awesome/archive/v$(fawe_ver).tar.gz
fawe_csrc = $(fawe_dir)/css/font-awesome.min.css
fawe_fsrc = $(fawe_dir)/fonts/fontawesome-webfont.woff2
fawe_cout = $(DIST_DIR)/css/$(notdir $(fawe_csrc))
fawe_fout = $(DIST_DIR)/fonts/$(notdir $(fawe_fsrc))

.PHONY: fawe clean-fawe clobber-fawe
fawe: $(fawe_cout) $(fawe_fout)

clean-fawe:
	$(Q)rm -f $(fawe_cout) $(fawe_fout)

clobber-fawe: clean-fawe
	$(Q)rm -rf $(fawe_dir)
	$(Q)rm -f $(fawe_tgz)

$(fawe_cout): $(fawe_key)
	$(call ECHO_W,"Locating $(fawe_name) css ($@)")
	$(Q)mkdir -p $(dir $@) && cp $(fawe_csrc) $@

$(fawe_fout): $(fawe_key)
	$(call ECHO_W,"Locating $(fawe_name) font ($@)")
	$(Q)mkdir -p $(dir $@) && cp $(fawe_fsrc) $@

$(fawe_key): $(fawe_tgz)
	$(call ECHO_W,"Unpacking $(fawe_name) tarball ($<)")
	$(Q)tar -C $(dir $<) -xf $< && touch $@

$(fawe_tgz):
	$(call ECHO_C,"Downloading $(fawe_name) tarball ($(fawe_url))")
	$(Q)mkdir -p $(dir $@) && curl -L -o $@ "$(fawe_url)"

#--------------------------------------------------------------------------------
# Ace
#

ace_name  = Ace
ace_ver   = 1.2.3
ace_url   = https://github.com/ajaxorg/ace-builds/archive/v$(ace_ver).tar.gz
ace_dir   = $(dwld_dir)/ace-builds-$(ace_ver)
ace_tgz   = $(ace_dir).tar.gz
ace_key   = $(ace_dir)/.unpacked
ace_src   = $(ace_dir)/src-min-noconflict
ace_out   = $(DIST_DIR)/ace

.PHONY: ace clean-ace clobber-ace
ace: $(ace_out)

clean-ace:
	$(Q)rm -rf $(ace_out)

clobber-ace: clean-ace
	$(Q)rm -rf $(ace_dir)
	$(Q)rm -f $(ace_tgz)

$(ace_out): $(ace_key)
	$(call ECHO_W,"Locating $(ace_name) scripts ($@)")
	$(Q)mkdir -p $(dir $@) && cp -r $(ace_src) $(ace_out)

$(ace_key): $(ace_tgz)
	$(call ECHO_W,"Unpacking $(ace_name) tarball ($<)")
	$(Q)tar -C $(dir $<) -xf $< && touch $@

$(ace_tgz):
	$(call ECHO_C,"Downloading $(ace_name) tarball ($(ace_url))")
	$(Q)mkdir -p $(dir $@) && curl -L -o $@ "$(ace_url)"

#--------------------------------------------------------------------------------
# spin.js
#

spin_name = spin.js
spin_ver  = 2.3.2
spin_url  = https://github.com/fgnass/spin.js/archive/$(spin_ver).tar.gz
spin_dir  = $(dwld_dir)/spin.js-$(spin_ver)
spin_tgz  = $(spin_dir).tar.gz
spin_key  = $(spin_dir)/.unpacked
spin_src  = $(spin_dir)/spin.min.js
spin_out  = $(DIST_DIR)/$(notdir $(spin_src))

.PHONY: spin clean-spin clobber-spin
spin: $(spin_out)

clean-spin:
	$(Q)rm -f $(spin_out)

clobber-spin: clean-spin
	$(Q)rm -rf $(spin_dir)
	$(Q)rm -f $(spin_tgz)

$(spin_out): $(spin_key)
	$(call ECHO_W,"Locating $(spin_name) script ($@)")
	$(Q)mkdir -p $(dir $@) && cp $(spin_src) $@

$(spin_key): $(spin_tgz)
	$(call ECHO_W,"Unpacking $(spin_name) tarball ($<)")
	$(Q)tar -C $(dir $<) -xf $< && touch $@

$(spin_tgz):
	$(call ECHO_C,"Downloading $(spin_name) tarball ($(spin_url))")
	$(Q)mkdir -p $(dir $@) && curl -L -o $@ "$(spin_url)"

#--------------------------------------------------------------------------------
# jquery.spin.js
#

jqsp_name = jquery.spin.js
jqsp_ver  = -----
jqsp_url  = http://spin.js.org/jquery.spin.js
jqsp_src  = $(dwld_dir)/$(notdir $(jqsp_url))
jqsp_out  = $(DIST_DIR)/$(notdir $(jqsp_src))

.PHONY: jqsp clean-jqsp clobber-jqsp
jqsp: $(jqsp_out)

clean-jqsp:
	$(Q)rm -f $(jqsp_out)

clobber-jqsp: clean-jqsp
	$(Q)rm -f $(jqsp_src)

$(jqsp_out): $(jqsp_src)
	$(call ECHO_W,"Locating $(jqsp_name) script ($@)")
	$(Q)mkdir -p $(dir $@) && cp $< $@

$(jqsp_src):
	$(call ECHO_C,"Downloading $(jqsp_name) script ($(jqsp_url))")
	$(Q)mkdir -p $(dir $@) && curl -L -o $@ "$(jqsp_url)"

#--------------------------------------------------------------------------------
# Bootbox
#

bbox_name = Bootbox
bbox_ver  = 4.4.0
bbox_url  = https://github.com/makeusabrew/bootbox/releases/download/v$(bbox_ver)/bootbox.min.js
bbox_src  = $(dwld_dir)/$(notdir $(bbox_url))
bbox_out  = $(DIST_DIR)/$(notdir $(bbox_src))

.PHONY: bbox clean-bbox clobber-bbox
bbox: $(bbox_out)

clean-bbox:
	$(Q)rm -f $(bbox_out)

clobber-bbox: clean-bbox
	$(Q)rm -f $(bbox_src)

$(bbox_out): $(bbox_src)
	$(call ECHO_W,"Locating $(bbox_name) script ($@)")
	$(Q)mkdir -p $(dir $@) && cp $< $@

$(bbox_src):
	$(call ECHO_C,"Downloading $(bbox_name) script ($(bbox_url))")
	$(Q)mkdir -p $(dir $@) && curl -L -o $@ "$(bbox_url)"

#--------------------------------------------------------------------------------
# jQuery-ScrollTabs
#

jqst_name = jQuery-ScrollTabs
jqst_ver  = 2.0.0
jqst_url  = https://github.com/joshreed/jQuery-ScrollTabs/archive/$(jqst_ver).tar.gz
jqst_dir  = $(dwld_dir)/jQuery-ScrollTabs-$(jqst_ver)
jqst_tgz  = $(jqst_dir).tar.gz
jqst_key  = $(jqst_dir)/.unpacked
jqst_src1 = $(jqst_dir)/js/jquery.scrolltabs.js
jqst_out1 = $(DIST_DIR)/$(notdir $(jqst_src1))
jqst_src2 = $(jqst_dir)/js/jquery.mousewheel.js
jqst_out2 = $(DIST_DIR)/$(notdir $(jqst_src2))
jqst_csrc = $(jqst_dir)/css/scrolltabs.css
jqst_cout = $(DIST_DIR)/css/$(notdir $(jqst_csrc))

.PHONY: jqst clean-jqst clobber-jqst
jqst: $(jqst_out1) $(jqst_out2) $(jqst_cout)

clean-jqst:
	$(Q)rm -f $(jqst_out1) $(jqst_out2) $(jqst_cout)

clobber-jqst: clean-jqst
	$(Q)rm -rf $(jqst_dir)
	$(Q)rm -f $(jqst_tgz)

$(jqst_out1): $(jqst_key)
	$(call ECHO_W,"Locating $(jqst_name) script ($@)")
	$(Q)mkdir -p $(dir $@) && cp $(jqst_src1) $@

$(jqst_out2): $(jqst_key)
	$(call ECHO_W,"Locating $(jqst_name) script ($@)")
	$(Q)mkdir -p $(dir $@) && cp $(jqst_src2) $@

$(jqst_cout): $(jqst_key)
	$(call ECHO_W,"Locating $(jqst_name) css ($@)")
	$(Q)mkdir -p $(dir $@) && cp $(jqst_csrc) $@

$(jqst_key): $(jqst_tgz)
	$(call ECHO_W,"Unpacking $(jqst_name) tarball ($<)")
	$(Q)tar -C $(dir $<) -xf $< && touch $@

$(jqst_tgz):
	$(call ECHO_C,"Downloading $(jqst_name) tarball ($(jqst_url))")
	$(Q)mkdir -p $(dir $@) && curl -L -o $@ "$(jqst_url)"

#--------------------------------------------------------------------------------
# Canarium
#

cana_name = Canarium
cana_ver  = 0.9.8
cana_url  = https://github.com/kimushu/canarium/archive/v$(cana_ver).tar.gz
cana_dir  = $(dwld_dir)/canarium-$(cana_ver)
cana_tgz  = $(cana_dir).tar.gz
cana_key  = $(cana_dir)/.unpacked
cana_src  = $(cana_dir)/js/canarium.min.js
cana_out  = $(DIST_DIR)/$(notdir $(cana_src))

.PHONY: cana clean-cana clobber-cana
cana: $(cana_out)

clean-cana:
	$(Q)rm -f $(cana_out)

clobber-cana: clean-cana
	$(Q)rm -rf $(cana_dir)
	$(Q)rm -f $(cana_tgz)

$(cana_out): $(cana_key)
	$(call ECHO_W,"Locating $(cana_name) script ($@)")
	$(Q)mkdir -p $(dir $@) && cp $(cana_src) $@

$(cana_key): $(cana_tgz)
	$(call ECHO_W,"Unpacking $(cana_name) tarball ($<)")
	$(Q)tar -C $(dir $<) -xf $< && touch $@

$(cana_tgz):
	$(call ECHO_C,"Downloading $(cana_name) tarball ($(cana_url))")
	$(Q)mkdir -p $(dir $@) && curl -L -o $@ "$(cana_url)"

#--------------------------------------------------------------------------------
# jsTree
#

jstr_name = jsTree
jstr_ver  = 3.3.1
jstr_url  = https://github.com/vakata/jstree/archive/$(jstr_ver).tar.gz
jstr_dir  = $(dwld_dir)/jstree-$(jstr_ver)
jstr_tgz  = $(jstr_dir).tar.gz
jstr_key  = $(jstr_dir)/.unpacked
jstr_src  = $(jstr_dir)/dist/jstree.min.js
jstr_out  = $(DIST_DIR)/$(notdir $(jstr_src))

.PHONY: jstr clean-jstr clobber-jstr
jstr: $(jstr_out)

clean-jstr:
	$(Q)rm -f $(jstr_out)

clobber-jstr: clean-jstr
	$(Q)rm -rf $(jstr_dir)
	$(Q)rm -f $(jstr_tgz)

$(jstr_out): $(jstr_key)
	$(call ECHO_W,"Locating $(jstr_name) script ($@)")
	$(Q)mkdir -p $(dir $@) && cp $(jstr_src) $@

$(jstr_key): $(jstr_tgz)
	$(call ECHO_W,"Unpacking $(jstr_name) tarball ($<)")
	$(Q)tar -C $(dir $<) -xf $< && touch $@

$(jstr_tgz):
	$(call ECHO_C,"Downloading $(jstr_name) tarball ($(jstr_url))")
	$(Q)mkdir -p $(dir $@) && curl -L -o $@ "$(jstr_url)"

#--------------------------------------------------------------------------------
# CSS generation (from less)
#

css_src   = $(VIEW_DIR)/window.less
css_out   = $(DIST_DIR)/css/window.css
css_link  = $(VIEW_DIR)/css/window.css

lessc_opts = --no-ie-compat --clean-css --include-path=$(dwld_dir)

.PHONY: css clean-css clobber-css
css: $(css_out) $(css_link)

clean-css: clean-twbs
	$(Q)rm -f $(css_out) $(css_link)

clobber-css: clean-css

$(css_out): $(css_src) $(twbs_key) $(firstword $(lessc)) $(MAKEFILE_LIST)
	$(call ECHO_W,"Compiling CSS ($@)")
	$(Q)mkdir -p $(dir $@)
	$(Q)$(LESSC) $(lessc_opts) $< > $@ || (rm -f $@; false)

$(css_link): $(css_out)
	$(Q)mkdir -p $(dir $@) && ln -sr $< $@

#--------------------------------------------------------------------------------
# Image files
#

img_sdir  = $(VIEW_DIR)/images
img_ddir  = $(DIST_DIR)/images
img_files = \
	mruby_logo_red_cropped.png \
	peridotcraft_logo_1.png \
	emscripten_logo_full_cropped.png \
	rubic_cube2x2_16.png \
	rubic_cube2x2_20.png \
	rubic_cube2x2_32.png \
	rubic_cube2x2_48.png \
	rubic_cube2x2_128.png \
	rubic_text_24.png \
	rubic_text_48.png \
	boards/no_image_48.png \
	boards/peridot_64x64.png \
	boards/wrbb_64x64.png \
	boards/grcitrus_64x64.png \
	icons/mruby_16.png \
	icons/javascript_16.png \
	icons/lua_16.png \
	icons/python_16.png

img_out   = $(addprefix $(img_ddir)/,$(img_files))

.PHONY: images clean-images clobber-images
images: $(img_out)

$(img_ddir)/%: $(img_sdir)/%
	$(Q)mkdir -p $(dir $@) && cp $< $@ && chmod a-x $@

clean-images:
	$(Q)rm -f $(img_out)

clobber-images: clean-images

#--------------------------------------------------------------------------------
# HTML generation
#

html_gen  = $(VIEW_DIR)/generate_html.rb
html_src  = $(VIEW_DIR)/main.html
html_out  = $(DIST_DIR)/window.html
html_dep  = $(VIEW_DIR)/.$(notdir $(html_src)).dep

.PHONY: html clean-html clobber-html
html: $(html_out) css images $(modules)

clean-html: $(addprefix clean-,css images $(modules))
	$(Q)rm -f $(html_out)

clobber-html: clean-html
clobber-html: $(addprefix clobber-,css images $(modules))

$(html_out): $(html_gen) $(MAKEFILE_LIST)
	$(call ECHO_W,"Generating HTML ($@)")
	$(Q)mkdir -p $(dir $@)
	$(Q)ruby $< -d $(html_dep) -v -s $(html_src) $@

-include $(html_dep)

