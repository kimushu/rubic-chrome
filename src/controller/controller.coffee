"use strict"
# Pre dependencies
UnJSONable = require("util/unjsonable")
require("util/primitive")

###*
@class Controller
  Base class of controller (Controller)
@extends UnJSONable
###
module.exports = class Controller extends UnJSONable
  null

  #--------------------------------------------------------------------------------
  # Public properties
  #

  ###*
  @property {boolean} activated
    Is this controller activated
  @readonly
  ###
  @property("activated",
    get: -> @window.controller == this
  )

  ###*
  @static
  @property {AppWindow} appWindow
    The AppWindow instance
  @readonly
  ###
  @property("appWindow", get: -> chrome?.app.window?.current())

  ###*
  @property {Window} window
    window object
  @readonly
  ###
  @property("window", get: -> @_window)

  ###*
  @property {Function} $
    jQuery core function
  @readonly
  ###
  @property("$", get: -> @window.$)

  #--------------------------------------------------------------------------------
  # Private variables / constants
  #

  DELAY_AFTER_LOADING = 1000

  #--------------------------------------------------------------------------------
  # Public methods
  #

  ###*
  @method
    Activate controller
  @return {Promise}
    Promise object
  ###
  activate: ->
    if @window.controller == this
      return Promise.reject(Error("Already activated"))
    return Promise.resolve(
    ).then(=>
      return @window.controller?.deactivate()
    ).then(=>
      body = @$("body")
      return unless body.hasClass("loading")
      return Promise.delay(DELAY_AFTER_LOADING).then(=>
        body.removeClass("loading")
        if @window.reset_all
          App.popupInfo(I18n.getMessage("Cache_has_been_initialized"))
        return
      )
    ).then(=>
      @window.controller = this
      App.info.verbose("Controller#activate(%o)", this)
      unless (doc = @window.document).translated
        doc.translated = true
        console.log("Translating document (#{I18n.lang})")
        I18n.translateDocument(doc)
      return
    ) # return Promise.resolve().then()...

  ###*
  @method
    Deactivate controller
  @return {Promise}
    Promise object
  ###
  deactivate: ->
    return Promise.resolve(
    ).then(=>
      App.info.verbose("Controller#deactivate(%o)", this)
    ).then(=>
      @window.controller = null
    ) # return Promise.resolve().then()...

  #--------------------------------------------------------------------------------
  # Protected methods
  #

  ###*
  @protected
  @method constructor
    Constructor of Controller class
  @param {Window} _window
    window object
  ###
  constructor: (@_window) ->
    return

  ###*
  @protected
  @method
    Create modal spinner
  @param {Object} opts
    Options passed to Spinner
  @return {Object}
    Spinner class
  ###
  modalSpin: (opts) ->
    jq = @$
    return @_window._modalSpinner or= {
      _spinElement: jq("#modal-spin").spin({color: "#fff"})
      _textElement: jq("#modal-spin .spin-text")
      _depth: 0
      _start: 0
      _window: @_window
      html: (value) ->
        @_textElement.html(value)
        return this
      text: (value) ->
        @_textElement.text(value)
        return this
      show: (opts) ->
        if ++@_depth == 1
          @_start = Date.now()
          @_spinElement.modal(jq.extend({
            show: true
            backdrop: "static"
            keyboard: false
          }, opts))
        return this
      hide: (atleast = 0) ->
        last = Math.max(0, atleast - (Date.now() - @_start))
        if last > 0
          @_window.setTimeout(@hide.bind(this, 0), last)
          return
        if (@_depth = Math.max(@_depth - 1, 0)) == 0
          @_spinElement.modal("hide")
        else
          @_textElement.html("")
        return this
    }

# Post dependencies
App = require("app/app")
I18n = require("util/i18n")
