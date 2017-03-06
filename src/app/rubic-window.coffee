"use strict"
require("../util/primitive")
{sprintf} = require("sprintf-js")
{BrowserWindow} = require("electron")
path = require("path")
url = require("url")
delayed = require("../util/delayed")

###*
Window manager for Main-process

@class RubicWindow
###
module.exports =
class RubicWindow

  constructor: (options) ->
    console.log("new RubicWindow()")
    dev_tools = !!options?["--dev-tools"]
    @_options = {dev_tools}
    @_browserWindow = null
    return

  @DEFAULT_WIDTH:   640
  @DEFAULT_HEIGHT:  480
  @MINIMUM_WIDTH:   560
  @MINIMUM_HEIGHT:  240

  @EVENT_DELAY_MS:  500

  ###*
  Open main window

  @method open
  @return {Promise|undefined}
    Promise object
  ###
  open: ->
    console.log("RubicWindow#open()")
    return Promise.resolve() if @_browserWindow?
    return Promise.resolve(
    ).then(=>
      return global.rubic.settings.get({window: null, debug: null})
    ).then(({window: values, debug}) =>
      bounds = values?.bounds
      zoom_ratio = (values?.zoom_ratio_x10 ? 10) / 10

      # Create BrowserWindow instance
      console.log("[RubicWindow] creating Electron BrowserWindow")
      @_browserWindow = new BrowserWindow(
        icon: path.join(__dirname, "..", "..", "view", "images", "rubic_cube2x2.ico")
        width: bounds?.width ? @constructor.DEFAULT_WIDTH
        height: bounds?.height ? @constructor.DEFAULT_HEIGHT
        useContentSize: true
        minWidth: @constructor.MINIMUM_WIDTH * zoom_ratio
        minHeight: @constructor.MINIMUM_HEIGHT * zoom_ratio
        webPreferences:
          zoomFactor: zoom_ratio
      )

      # Register event handlers for this window
      @_browserWindow.on("closed", =>
        console.log("[RubicWindow] closed")
        @_browserWindow = null
      )
      @_browserWindow.on("resize", delayed @constructor.EVENT_DELAY_MS, =>
        console.log("[RubicWindow] resize (delayed)")
        {width, height} = @_browserWindow.getContentBounds()
        global.rubic.settings.set(
          "window.bounds": {width, height}
        )
      )

      # Disable menu bar
      @_browserWindow.setMenu(null)

      # Load page contents
      @_browserWindow.loadURL(url.format(
        pathname: path.join(__dirname, "..", "..", "dist", "window.html") # 仮
        protocol: "file:"
        slashes: true
      ))

      # Open devTools for debugging
      if @_options.dev_tools or debug?.devTools
        @_browserWindow.webContents.openDevTools()

      console.log("[RubicWindow] waiting BrowserWindow open")
      return  # Last PromiseValue
    ) # return Promise.resolve().then()...

  ###*
  Message ID for debug prints

  @static
  @attribute MSGID_DEBUGPRINT
  @readOnly
  ###
  @MSGID_DEBUGPRINT: "debug-print"

  ###*
  Output debug message

  @method debugPrint
  @param {"log"|"info"|"warn"|"error"} level
    Severity level
  @param {string|function} msg
    Message string or function to generate message
  @param {Object} ...params
    Parameters for substituting by sprintf
  ###
  debugPrint: (level, msg, params...) ->
    timestamp = Date.now()
    if typeof(msg) == "function"
      msg = msg()
    else
      msg = sprintf(msg, params...)
    @_browserWindow?.webContents.send(
      @constructor.MSGID_DEBUGPRINT
      level
      timestamp
      msg
    )
    return

