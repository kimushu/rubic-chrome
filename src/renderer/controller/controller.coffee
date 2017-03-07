"use strict"
require("../../util/primitive")

###*
Base class of controller (Controller, Renderer-process)

@class Controller
###
module.exports =
class Controller

  constructor: ->
    @_keyBinds = []

  ###*
  Current controller (Use activate() to change)

  @static
  @property {Controller} current
  @readOnly
  ###
  @staticProperty "current", get: -> Controller._current

  @_current: null

  ###*
  Is this controller activated

  @property {boolean} activated
  @readOnly
  ###
  @getter "activated", -> Controller._current == this

  ###*
  Activate controller (Subclass should call this first)

  @method activate
  @return {Promise|undefined}
    Promise object
  ###
  activate: ->
    return Promise.resolve() if Controller._current == this
    return Promise.resolve(
    ).then(=>
      # Deactivate current controller
      return Controller._current?.deactivate()
    ).then(=>
      # Set current controller
      Controller._current = this
      console.log("[#{@constructor.name}] Activated")
      return  # Last PromiseValue
    )

  ###*
  Deactivate controller (Subclass should call this last)

  @method deactivate
  @return {Promise|undefined}
    Promise object
  ###
  deactivate: ->
    console.log("[#{@constructor.name}] Deactivated")
    Controller._current = null
    return Promise.resolve()

  #--------------------------------------------------------------------------------
  # Protected methods
  #

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
    isMac = (process.platform == "darwin")
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

