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
      )
    ).then(=>
      @window.controller = this
      App.info.verbose({"Controller#activate": this})
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
      App.info.verbose({"Controller#deactivate": this})
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
    Bind DOM event handlers
  @param {string} sel
    DOM selector for jQuery
  @param {string} event
    Event name
  @param {Function} fn
    Function (automatically binded to "this")
  @param {Object[]} args
    Additional arguments to Function#bind
  @return {jQuery}
    jQuery object
  ###
  bindAction: (sel, event, fn, args...) ->
    ((@_actions or= {})[sel] or= {})[event] = fn
    return @$(sel).unbind(event).bind(event, fn.bind(this, args...))

  ###*
  @protected
  @method
    Unbind all DOM event handlers
  @return {undefined}
  ###
  unbindActions: ->
    for sel, events of (@_actions or {})
      @$(sel).unbind(event) for event, fn of events
    @_actions = {}
    return

  ###*
  @protected
  @method
    Setup HTML elements
  @param {Object} map
  ###

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
      html: (value) ->
        @_textElement.html(value)
        return this
      text: (value) ->
        @_textElement.text(value)
        return this
      show: (opts) ->
        if ++@_depth == 1
          @_spinElement.modal(jq.extend({
            show: true
            backdrop: "static"
            keyboard: false
          }, opts))
        return this
      hide: ->
        if (@_depth = Math.max(@_depth - 1, 0)) == 0
          @_spinElement.modal("hide")
        @_textElement.html("")
        return this
    }

# Post dependencies
App = require("app/app")
I18n = require("util/i18n")
