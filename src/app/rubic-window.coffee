"use strict"
require("../util/primitive")
{sprintf} = require("sprintf-js")
{BrowserWindow, ipcMain} = require("electron")
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
    ).then(({window, debug}) =>
      bounds = window?.bounds
      zoom_ratio = (window?.zoom_ratio_x10 ? 10) / 10

      # Create BrowserWindow instance
      console.log("[RubicWindow] creating Electron BrowserWindow")
      @_browserWindow = new BrowserWindow(
        icon: path.join(__dirname, "..", "..", "static", "images", "rubic_cube2x2.ico")
        x: if bounds?.x? and bounds?.y? then bounds.x else null
        y: if bounds?.x? and bounds?.y? then bounds.y else null
        width: bounds?.width ? @constructor.DEFAULT_WIDTH
        height: bounds?.height ? @constructor.DEFAULT_HEIGHT
        useContentSize: true
        minWidth: @constructor.MINIMUM_WIDTH * zoom_ratio
        minHeight: @constructor.MINIMUM_HEIGHT * zoom_ratio
        show: false
        webPreferences:
          zoomFactor: zoom_ratio
      )

      @_browserWindow.maximize() if window?.maximized
      @_browserWindow.show()

      # Register event handlers for this window
      @_browserWindow.on("closed", =>
        console.log("[RubicWindow] closed")
        @_browserWindow = null
      )
      move_or_resize = =>
        maximized = @_browserWindow.isMaximized()
        minimized = @_browserWindow.isMinimized()
        if maximized
          console.log("[RubicWindow] maximized")
          global.rubic.settings.set(
            "window.maximized": true
          )
        else if minimized
          console.log("[RubicWindow] minimized")
        else
          {x, y} = @_browserWindow.getBounds()
          {width, height} = @_browserWindow.getContentBounds()
          global.rubic.settings.set(
            "window.bounds": {width, height, x, y}
            "window.maximized": false
          )
      @_browserWindow.on("move", delayed @constructor.EVENT_DELAY_MS, =>
        console.log("[RubicWindow] move (delayed)")
        move_or_resize()
      )
      @_browserWindow.on("resize", delayed @constructor.EVENT_DELAY_MS, =>
        console.log("[RubicWindow] resize (delayed)")
        move_or_resize()
      )

      # Disable menu bar
      @_browserWindow.setMenu(null)

      # Open devTools for debugging
      if @_options.dev_tools or debug?.devTools
        @_browserWindow.webContents.openDevTools()

      # Register listener
      promise = new Promise((resolve) =>
        ipcMain.on("bridge-opened", (event) =>
          console.log("[RubicWindow] received bridge-opened message")
          resolve()
        )
        ipcMain.on("translation-complete", (event) =>
          console.log("[RubicWindow] received translation-complete message")
        )
      )

      # Load page contents
      @_browserWindow.loadURL(url.format(
        pathname: path.join(__dirname, "..", "..", "static", "index.html")
        protocol: "file:"
        slashes: true
      ))

      console.log("[RubicWindow] waiting BrowserWindow open")
      return promise
    ) # return Promise.resolve().then()...

  ###*
  Output debug message

  @method debugPrint
  @param {"log"|"info"|"warn"|"error"} level
    Severity level
  @param {string|function} msg
    Message string or function to generate message
  @param {Object} ...params
    Parameters for substituting by sprintf
  @return {undefined}
  ###
  debugPrint: (level, msg, params...) ->
    timestamp = Date.now()
    if typeof(msg) == "function"
      msg = msg()
    else
      msg = sprintf(msg, params...)
    @_browserWindow?.webContents.send(
      "debug-print"
      level
      timestamp
      msg
    )
    return

