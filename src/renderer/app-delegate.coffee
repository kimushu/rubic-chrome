"use strict"
require("../util/primitive")
{ipcRenderer} = require("electron")
path = require("path")
{Disposable} = require("event-kit")
{createCaller} = require("../util/promisified-call")

###*
Delegate for RubicApp (Renderer-process)

@class AppDelegate
###
module.exports =
class AppDelegate

  constructor: ->
    return

  ###*
  Create a AppDelegate instance

  @static
  @method open
  @return {Promise|AppDelegate}
    Promise object with instance
  ###
  @open: () ->
    console.log("AppDelegate.open()")
    return new AppDelegate()._initialize()

  ###*
  Initialize instance

  @private
  @method _initialize
  @return {Promise|AppDelegate}
    Promise object with instance
  ###
  _initialize: ->
    console.log("AppDelegate#_initialize()")

    # Register AppDelegate instance to global
    global.rubic = this

    # Initialize accessor for RubicSettings
    @_settings =
      get: createCaller("settings-get", ipcRenderer)
      set: createCaller("settings-set", ipcRenderer)

    # Start request receiver for RubicWindow
    ipcRenderer.on("debug-print", (event, level, timestamp, msg) =>
      console[level].call(console, msg)
    )

    # Create callers
    @_callers = {}
    (@_callers[name] = createCaller(name, ipcRenderer)) for name in [
      "open-sketch", "save-sketch", "build-sketch",
    ]

    @send("delegate-ready")
    return Promise.resolve(this)

  ###*
  Accessor for RubicSettings

  @property {Object} settings
  @readOnly
  ###
  @getter "settings", -> @_settings

  ###*
  Name of this application

  @property {string} name
  @readOnly
  ###
  @getter "name", -> "Rubic"

  ###*
  Version string of this application

  @property {string} version
  @readOnly
  ###
  @getter "version", ->
    @_version = require(
      path.join(__dirname, "..", "..", "package.json")
    ).version unless @_version?
    return @_version

  ###*
  Send a message to main-process

  @method send
  @param {string} channel
  @param {Object} ...args
  @return {undefined}
  ###
  send: (channel, args...) ->
    ipcRenderer.send(channel, args...)
    return

  ###*
  Create a new sketch or open an existing sketch.
  (Unsaved modification of current sketch will be discarded)

  @method openSketch
  @param {string} [dir]
    Path of sketch directory (if omitted, create a new sketch)
  @return {Promise|undefined}
  ###
  openSketch: (dir = null) ->
    return @_callers["open-sketch"](dir?.toString())

  ###*
  Save current sketch

  @method saveSketch
  @param {string} [dir]
    Path of sketch director (if omitted, overwrite the sketch)
  @return {Promise|undefined}
  ###
  saveSketch: (dir = null) ->
    return @_callers["save-sketch"](dir?.toString())

  ###*
  Build current sketch
  (This API does not save sketch before building)

  @method buildSketch
  @return {Promise|undefined}
  ###
  buildSketch: ->
    return @_callers["build-sketch"]()

  ###*
  Register event handler for switching sketch

  @method onSketchSwitched
  @param {function} callback
  @return {Disposable}
  ###
  onSketchSwitched: (callback) ->
    channel = "on-sketch-switched"
    cb = (event) -> callback()
    ipcRenderer.on(channel, cb)
    return new Disposable =>
      ipcRenderer.removeListener(channel, cb)

