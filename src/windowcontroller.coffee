###*
@class Rubic.WindowController
  Base controller for windows (Controller)
###
class Rubic.WindowController
  DEBUG = Rubic.DEBUG or 0

  ###*
  @protected
  @property {AppWindow}
    AppWindow instance of chrome
  @readonly
  ###
  @property("appWindow", get: -> @_appWindow)

  ###*
  @protected
  @property {Object}
    JavaScript window object for this AppWindow
  @readonly
  ###
  @property("window", get: -> @_window)

  ###*
  @property {jQuery}
    jQuery object for this window
  @readonly
  ###
  @property("$", get: -> @_$)

  ###*
  @protected
  @method constructor
    Constructor of WindowController
  ###
  constructor: ->
    return

  ###*
  @protected
  @method
    Start controller
  @param {string} html
    Filename of html source
  @param {Object} [options]
    Options for chrome.app.window.create
  @param {function():void}  [callback]
    Callback function
  @return {void}
  ###
  start: (html, options, callback) ->
    (merged_options = options or {}).id = @constructor.name
    chrome.app.window.create(
      html
      merged_options
      (createdWindow) =>
        # Chrome sometimes raises spurious call with createdWindow==undefined
        return unless createdWindow

        # Store controller members
        @_appWindow = createdWindow
        @_window = @appWindow.contentWindow

        # Store global members
        @window.app = Rubic.App.getInstance()
        @window.controller = this
        @window.Rubic = Rubic

        callback?()
        return
    )
    return

  ###*
  @protected
  @method
    Event handler on document.onload
  @return {void}
  ###
  onLoad: ->
    Rubic.I18nT(@$)
    return

  ###*
  @static
  @method
    Fire onload event
  @param {Object} contentWindow
    Global window object of new window
  @return {void}
  ###
  @fireOnLoad: (contentWindow) ->
    contentWindow.controller._fireOnLoad()
    return

  ###*
  @private
  @method
    Fire onload event
  @return {void}
  ###
  _fireOnLoad: ->
    app.log({info: "#{@constructor.name} loaded", data: this})
    # Store jQuery object with short name
    @_$ = @window.$
    # Fire event
    @onLoad()
    return

