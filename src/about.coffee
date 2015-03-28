###*
@class
About dialog
###
class About
  ###*
  [UI action] Show about dialog
  ###
  @show: ->
    manifest = chrome.runtime.getManifest()
    # Make message of self information
    msg = """
    <div style="
      overflow-x: hidden;
      overflow-y: scroll;
      max-height: 250px;
      margin-left: 16px;
      margin-right: 16px;">
      <div class="row row-vcenter"><div class="col-xs-12" style="font-size: large;">About this application:</div></div>
      <div class="row row-vcenter">
        <div class="col-xs-4 col-vcenter text-center"><h1>#{manifest.name}</h1></div>
        <div class="col-xs-8 col-vcenter" style="font-size: small;">
          #{manifest.name} is an IDE for prototyping on embedded-boards with Ruby language.
          <br><span style="font-weight: bold;">Version: #{manifest.version}</span>
          <br>Author: <a href="http://github.com/kimushu/rubic" target="_blank">@kimu_shu</a>
        </div>
      </div>
    """
    # Make supporters list
    for key in ["platform", "application"]
      msg += """
      <div class="row"><div class="col-xs-12"><hr class="thin-hr"></div></div>
      <div class="row"><div class="col-xs-12">Rubic #{key} is supported by:</div></div>
      """
      index = 0
      for item in @_list[key]
        msg += "<div class=\"row row-vcenter\">\n" if (index % 3) == 0
        msg += """
        <div class="col-xs-4 col-vcenter text-center">
          <a href="#{item.url}" target="_blank" title="#{item.name} - #{item.desc}">
        """
        if item.image?
          msg += "<img class=\"supporter-logo\" src=\"images/#{item.image}\">\n"
        else
          msg += "#{item.name}\n"
        msg += """
          </a>
        </div><!-- /.col-xs-4 -->
        """
        msg += "</div><!-- /.row -->\n" if (index % 3) == 2
        index += 1
      unless (index % 3) == 0
        msg += """
          <div class="col-xs-#{(3-(index%3))*4} col-vcenter"></div>
        </div><!-- /.row -->
        """
    msg += "</div>"
    bootbox.dialog({
      message: msg
      closeButton: false
      buttons: {success: {label: "OK"}}
    })

  ###
  [UI event] Show about dialog
  ###
  $(".action-about").click(=>
    @show()
  )

  ###*
  @private
  List of supporters
  ###
  @_list:
    platform: [
      {
        image: "mruby_logo_red.svg"
        name: "mruby"
        desc: "The lightweight implementation of the Ruby language"
        url: "http://www.mruby.org/"
      }
      {
        image: "peridotcraft_logo_1.png"
        name: "PERIDOT"
        desc: "Simple & Compact FPGA"
        url: "https://peridotcraft.com/"
      }
      {
        image: "Emscripten_logo_full.png"
        name: "emscripten"
        desc: "An LLVM-based project that compiles C and C++ into highly-optimizable JavaScript"
        url: "http://kripken.github.io/emscripten-site/"
      }
    ]
    application: [
      {
        name: "jQuery"
        desc: "A fast, small, and feature-rich JavaScript library"
        url: "https://jquery.com/"
      }
      {
        name: "Bootstrap"
        desc: "A sleek, intuitive, and powerful movile first front-end framework for faster and easier web development"
        url: "http://getbootstrap.com/"
      }
      {
        name: "Ace"
        desc: "The high performance code editor for the web"
        url: "http://ace.c9.io/"
      }
      {
        name: "Bootstrap Notify"
        desc: "The plugin helps to turn standard bootstrap alerts into &ldquo;glowl&rdquo; like notifications"
        url: "http://bootstrap-growl.remabledesigns.com/"
      }
      {
        name: "Bootbox.js"
        desc: "Alert, confirm and flexible modal dialogs for the Bootstrap framework"
        url: "http://bootboxjs.com/"
      }
      {
        name: "js-yaml"
        desc: "YAML parser for JavaScript"
        url: "http://nodeca.github.io/js-yaml/"
      }
      {
        name: "spin.js"
        desc: "A spinning activity indicator"
        url: "http://fgnass.github.io/spin.js/"
      }
    ]

