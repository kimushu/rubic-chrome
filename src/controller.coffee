# Pre dependencies
UnJSONable = require("./unjsonable")

###*
@class Controller
  Base class of controller (Controller)
###
class Controller extends UnJSONable
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
  @property("appWindow", get: -> chrome.app.window.current())

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
  # Public methods
  #

  ###*
  @method
    Activate controller
  @return {undefined}
  ###
  activate: (args...) ->
    return if @window.controller == this
    @window.controller?.deactivate()
    @window.controller = this
    App.info({"Controller#activate": this})
    if @window.loaded?
      Promise.resolve().then(=>
        @onActivated(args...)
      )
    else
      @$(@window).load(=>
        @window.loaded = true
        @onActivated(args...)
      )
    return

  ###*
  @method
    Deactivate controller
  @return {undefined}
  ###
  deactivate: ->
    App.info.detail({"Controller#deactivate": this})
    @onDeactivated()
    @window.controller = null
    return

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
  @template
  @method
    Event listener for activate
  @return {undefined}
  ###
  onActivated: ->
    unless (doc = @window.document).translated
      doc.translated = true
      console.log("Translating document (#{I18n.lang})")
      I18n.translateDocument(doc)
    return

  ###*
  @protected
  @template
  @method
    Event listener for deactivate
  @return {undefined}
  ###
  onDeactivated: ->
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

module.exports = Controller

# Post dependencies
# (none)
App = require("./app")
I18n = require("./i18n")
