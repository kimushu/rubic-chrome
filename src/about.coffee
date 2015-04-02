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
      max-height: 303px;
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
      <div class="row row-vcenter"><div class="col-xs-12">Rubic #{key} is supported by:</div></div>
      """
      index = 0
      for item in @_supporters[key]
        name = escapeHtml(item.name)
        desc = escapeHtml(item.desc)
        msg += "<div class=\"row row-vcenter\">\n" if (index % 3) == 0
        msg += """
        <div class="col-xs-4 col-vcenter text-center">
          <a href="#{item.url}" target="_blank" title="#{name} - #{desc}">
        """
        if item.image?
          msg += "<img class=\"supporter-logo\" src=\"images/#{item.image}\">\n"
        else
          msg += "#{name}\n"
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
    for key, lic of @_licenses
      msg += """
      <div class="row"><div class="col-xs-12"><hr class="thin-hr"></div></div>
      <div class="row row-vcenter"><div class="col-xs-12">License (#{escapeHtml(key)}):</div></div>
      <div class="row">
        <div class="col-xs-12">
          #{escapeHtml(lic).replace(/\n/g, "<br>")}
        </div>
      </div>
      """
    msg += "</div>"
    bootbox.dialog({
      message: msg
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
  @_supporters:
    platform: [
      {
        image: "mruby_logo_red_cropped.png"
        name: "mruby"
        desc: "The lightweight implementation of the Ruby language"
        url: "http://www.mruby.org/"
        license: ["MIT License"]      # checked on 2015/03/28
      }
      {
        image: "peridotcraft_logo_1.png"
        name: "PERIDOT"
        desc: "Simple & Compact FPGA"
        url: "https://peridotcraft.com/"
        license: ["Apache License, Version 2.0"]  # checked on 2015/03/28
      }
      {
        image: "Emscripten_logo_full_cropped.png"
        name: "emscripten"
        desc: "An LLVM-based project that compiles C and C++ into highly-optimizable JavaScript"
        url: "http://kripken.github.io/emscripten-site/"
        license: ["MIT License",      # checked on 2015/03/28
                  "University of Illinois/NCSA Open Source License"]
      }
    ]
    application: [
      {
        name: "jQuery"
        desc: "A fast, small, and feature-rich JavaScript library"
        url: "https://jquery.com/"
        license: ["MIT License"]      # checked on 2015/03/29
      }
      {
        name: "Bootstrap"
        desc: "A sleek, intuitive, and powerful movile first front-end framework for faster and easier web development"
        url: "http://getbootstrap.com/"
        license: ["MIT License"]      # checked on 2015/03/29
      }
      {
        name: "Ace"
        desc: "The high performance code editor for the web"
        url: "http://ace.c9.io/"
        license: ["BSD Simplified"]   # checked on 2015/03/29
      }
      {
        name: "Bootstrap Notify"
        desc: "The plugin helps to turn standard bootstrap alerts into \"glowl\" like notifications"
        url: "http://bootstrap-growl.remabledesigns.com/"
        license: ["MIT License"]      # checked on 2015/03/29
      }
      {
        name: "Bootbox.js"
        desc: "Alert, confirm and flexible modal dialogs for the Bootstrap framework"
        url: "http://bootboxjs.com/"
        license: ["MIT License"]      # checked on 2015/03/29
      }
      {
        name: "js-yaml"
        desc: "YAML parser for JavaScript"
        url: "http://nodeca.github.io/js-yaml/"
        license: ["MIT License"]      # checked on 2015/03/29
      }
      {
        name: "spin.js"
        desc: "A spinning activity indicator"
        url: "http://fgnass.github.io/spin.js/"
        license: ["MIT License"]      # checked on 2015/03/29
      }
    ]

  ###*
  @private
  License declarations
  ###
  @_licenses: {
    "Rubic": """
    Copyright (c) 2015 Shuta Kimura (@kimu_shu)
    (The MIT License -- The permission notice is included at the end of this dialog)
    """
    #----------------------------------------------------------------
    "mruby": """
    Copyright (c) 2014 mruby developers
    (The MIT License -- The permission notice is included at the end of this dialog)
    """
    #----------------------------------------------------------------
    "canarium.js for PERIDOT": """
    Copyright (C) 2014, J-7SYSTEM Works. All rights Reserved.
    (Apache License, Version 2.0)

    * This module is a free sourcecode and there is NO WARRANTY.
    * No restriction on use. You can use, modify and redistribute it for personal, non-profit or commercial products UNDER YOUR RESPONSIBILITY.
    * Redistributions of source code must retain the above copyright notice.

    PERIDOT Project - https://github.com/osafune/peridot
    """
    #----------------------------------------------------------------
    "emscripten": """
    Copyright (c) 2010-2014 Emscripten authors, see AUTHORS file.
    (The MIT License -- The permission notice is included at the end of this dialog)
    """
    #----------------------------------------------------------------
    "Node.js included in emscripten": """
    Copyright Joyent, Inc. and other Node contributors. All rights reserved.
    (The MIT License -- The permission notice is included at the end of this dialog)
    """
    #----------------------------------------------------------------
    "jQuery": """
    Copyright jQuery Foundation and other contributors, https://jquery.org/
    (The MIT License -- The permission notice is included at the end of this dialog)
    """
    #----------------------------------------------------------------
    "Bootstrap": """
    Copyright (c) 2011-2015 Twitter, Inc
    (The MIT License -- The permission notice is included at the end of this dialog)
    """
    #----------------------------------------------------------------
    "Ace": """
    Copyright (c) 2010, Ajax.org B.V. All rights reserved.
    (3-Clause BSD License)

    Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

        * Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

        * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

        * Neither the name of Ajax.org B.V. nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL AJAX.ORG B.V. BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
    """
    #----------------------------------------------------------------
    "bootstrap-notify": """
    Copyright (c) 2014 Robert McIntosh
    (The MIT License -- The permission notice is included at the end of this dialog)
    """
    #----------------------------------------------------------------
    "Bootbox.js": """
    Copyright (C) 2011-2014 by Nick Payne nick@kurai.co.uk
    (The MIT License -- The permission notice is included at the end of this dialog)
    """
    #----------------------------------------------------------------
    "js-yaml": """
    Copyright (C) 2011-2015 by Vitaly Puzrin
    (The MIT License -- The permission notice is included at the end of this dialog)
    """
    #----------------------------------------------------------------
    "spin.js": """
    Copyright (c) 2011-2014 Felix Gnass [fgnass at neteye dot de]
    (The MIT License -- The permission notice is included at the end of this dialog)
    """
    #----------------------------------------------------------------
    "The MIT License": """
    Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
    """
    #----------------------------------------------------------------
  }

