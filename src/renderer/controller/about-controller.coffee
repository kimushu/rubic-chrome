"use strict"
# Pre dependencies
WindowController = require("controller/windowcontroller")

###*
@class AboutController
  Controller for about view (Controller, Singleton)
@extends WindowController
###
module.exports = class AboutController extends WindowController
  null
  instance = null

  #--------------------------------------------------------------------------------
  # Public properties
  #

  ###*
  @static
  @property {AboutController}
    The instance of this class
  @readonly
  ###
  @classProperty("instance", get: ->
    return instance or= new AboutController(window)
  )

  #--------------------------------------------------------------------------------
  # Private variables / constants
  #

  setupDone = false

  #--------------------------------------------------------------------------------
  # Protected methods
  #

  ###*
  @protected
  @inheritdoc Controller#activate
  ###
  activate: ->
    return super(
    ).then(=>
      return if setupDone
      setupDone = true
      $ = @$

      $("#rubic-version").text(App.version)
      $(".main-outer.when-about").scrollTop(0).
        find(".fold-header.fold-opened").removeClass("fold-opened")
      $(".license-mit:not(.replaced)").each((i, e) =>
        e.innerText =
          """
          The MIT License (MIT)

          #{e.innerText}

          Permission is hereby granted, free of charge, to any person obtaining a copy
          of this software and associated documentation files (the "Software"), to deal
          in the Software without restriction, including without limitation the rights
          to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
          copies of the Software, and to permit persons to whom the Software is
          furnished to do so, subject to the following conditions:

          The above copyright notice and this permission notice shall be included in
          all copies or substantial portions of the Software.

          THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
          IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
          FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
          AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
          LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
          OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
          THE SOFTWARE.
          """
      ).addClass("replaced")
      $(".license-bsdnew:not(.replaced)").each((i, e) =>
        e.innerText =
          """
          The BSD 3-clause License

          #{e.innerText}

          Redistribution and use in source and binary forms, with or without
          modification, are permitted provided that the following conditions are met:

          1. Redistributions of source code must retain the above copyright notice,
             this list of conditions and the following disclaimer.

          2. Redistributions in binary form must reproduce the above copyright notice,
             this list of conditions and the following disclaimer in the documentation
             and/or other materials provided with the distribution.

          3. Neither the name of the copyright holder nor the names of its contributors
             may be used to endorse or promote products derived from this software
             without specific prior written permission.

          THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
          AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
          IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
          ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
          LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
          CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
          SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
          INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
          CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
          ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
          THE POSSIBILITY OF SUCH DAMAGE.
          """
      ).addClass("replaced")
    ).then(=>
      $("body").addClass("controller-about")
      return
    ) # return super().then()...

  ###*
  @protected
  @inheritdoc Controller#deactivate
  ###
  deactivate: ->
    $ = @$
    $("body").removeClass("controller-about")
    return super()

  #--------------------------------------------------------------------------------
  # Private methods
  #

  ###*
  @private
  @method constructor
    Constructor of AboutController class
  @param {Window} window
    window object
  ###
  constructor: (window) ->
    super(window)
    return

# Post dependencies
App = require("app/app")
I18n = require("util/i18n")
