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
    console.log(this)
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

module.exports = Controller

# Post dependencies
I18n = require("./i18n")
