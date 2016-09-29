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
      doc = @window.document

      unless doc.translated
        doc.translated = true
        console.log("Translating document (#{I18n.lang})")
        I18n.translateDocument(doc)

      unless doc.keyListenerInstalled
        doc.keyListenerInstalled = true
        @$(doc).keydown(@_processKey.bind(this))

      @_keyBinds = []
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
      @_keyBinds = null
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

  ###*
  @protected
  @method
    Bind shortcut key
  @param {string} keys
    Key combination (ctrl/shift/alt/meta/mod)
  @param {string/Function} selector_callback
    jQuery selector or callback function when key pressed
  @return {string}
    Key presentation for UI (platform dependent)
  ###
  bindKey: (keys, selector_callback) ->
    isMac = (Preferences.os == "mac")
    cond = {shiftKey: false, ctrlKey: false, altKey: false, metaKey: false}
    ui = ""
    if keys.includes("ctrl+") or (!isMac and keys.includes("mod+"))
      ui += if isMac then "\u2303" else "Ctrl+"
      cond.ctrlKey = true
    if keys.includes("shift+")
      ui += if isMac then "\u21e7" else "Shift+"
      cond.shiftKey = true
    if keys.includes("alt+")
      ui += if isMac then "\u2325" else "Alt+"
      cond.altKey = true
    if keys.includes("meta+") or (isMac and keys.includes("mod+"))
      ui += if isMac then "\u2318" else "Meta+"
      cond.metaKey = true
    char = keys.match(/\+([a-z])$/i)[1].toUpperCase()
    ui += char
    cond.key = char
    if typeof(selector_callback) == "function"
      callback = selector_callback
    else if selector_callback?
      selector = selector_callback
      $ = @$
      obj = $(selector)
      for element in $(selector).filter(".key-stroke")
        obj = $(element)
        obj.attr("title", obj.attr("title").replace("_KEYS_", ui))
    @_keyBinds.push({
      condition: cond
      selector: selector
      callback: callback
    })
    return ui

  ###*
  @private
  @method
    Process shortcut keys
  @param {Event} event
    Event object
  ###
  _processKey: (event) ->
    return unless event.key.length == 1
    for bind in (@_keyBinds or [])
      cond = bind.condition
      continue unless (cond.shiftKey == event.shiftKey) and
                      (cond.ctrlKey == event.ctrlKey) and
                      (cond.altKey == event.altKey) and
                      (cond.metaKey == event.metaKey) and
                      (cond.key == event.key.toUpperCase())
      (callback = bind.callback)?()
      if (selector = bind.selector)?
        @$(selector).filter(":not(:disabled)").eq(0).click()
      event.preventDefault()
      break
    return

# Post dependencies
App = require("app/app")
I18n = require("util/i18n")
Preferences = require("app/preferences")
