###*
@class Rubic.WindowController
  Base controller for windows (Controller)
###
class Rubic.WindowController
  DEBUG = Rubic.DEBUG or 0

  ###*
  @protected
  @property {AppWindow} appWindow
    AppWindow instance of chrome
  @readonly
  ###
  @property("appWindow", get: -> @_appWindow)

  ###*
  @protected
  @property {Object} window
    JavaScript window object for this AppWindow
  @readonly
  ###
  @property("window", get: -> @_window)

  ###*
  @property {jQuery} $
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

        # Add event listeners
        @_appWindow.onClosed.addListener(=> @onClosed())

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
  @method
    Close window
  @return {void}
  ###
  close: ->
    @appWindow.close()
    return

  ###*
  @protected
  @method
    Event handler on appWindow.onClosed
  @return {void}
  ###
  onClosed: ->
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

  ###*
  @method
    Activate window
  @return {void}
  ###
  activate: ->
    @appWindow.focus()
    return

  ###*
  @protected
  @method
    Bind shortcut key
  @param {string} key
    Key combination by "Ctrl+A" like format
  @param {function():void}  callback
    Function called when key pressed
  @return {void}
  ###
  bindKey: (key, callback) ->
    # Get modifier
    mod = [(-> not @altKey), (-> not @ctrlKey), (-> not @shiftKey)]
    key = key.replace('Alt+', -> (mod[0] = (-> @altKey); ''))
    key = key.replace('Ctrl+', -> (mod[1] = (-> @ctrlKey); ''))
    key = key.replace('Shift+', -> (mod[2] = (-> @shiftKey); ''))

    # Get key code
    if key.match(/^[A-Z0-9]$/)
      code = key.charCodeAt(0)
    else
      match = key.match(/^F(\d+)$/)
      code = parseInt(match[1]) + 0x6f if match

    throw new Error("Unknown key name") unless code

    # Bind to document
    @$(@window.document).keydown((event) =>
      return unless event.keyCode == code
      for m in mod
        return unless m.call(event)
      callback(event)
      event.preventDefault()
    )
    return

