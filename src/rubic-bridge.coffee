"use strict"
require("./util/primitive")
{ipcRenderer} = require("electron")

###*
Bridge to main-process

@class RubicBridge
###
module.exports =
class RubicBridge

  constructor: ->
    return

  ###*
  Create a RubicBridge instance

  @static
  @method open
  @return {Promise|RubicBridge}
    Promise object with instance
  ###
  @open: () ->
    console.log("RubicBridge.open()")
    return new RubicBridge()._initialize()

  ###*
  Initialize instance

  @private
  @method _initialize
  @return {Promise|RubicBridge}
    Promise object with instance
  ###
  _initialize: ->
    console.log("RubicBridge#_initialize")

    # Register RubicBridge instance to global
    global.bridge = this

    # Initialize accessor for RubicSettings
    @_settings =
      get: @_promisifiedCall.bind(this, "settings-call", "get")
      set: @_promisifiedCall.bind(this, "settings-call", "set")
    @_requests = {}

    # Start request receiver for RubicWindow
    ipcRenderer.on("debug-print", (event, level, timestamp, msg) =>
      console[level].call(console, msg)
    )

    # Start response receiver for RubicSettings
    ipcRenderer.on("settings-reply", (event, id, data) =>
      req = @_requests[id]
      return unless req?
      delete @_requests[id]
      return req.reject(data.error) if data.error?
      return req.resolve(data.result)
    )

    @send("bridge-opened")
    return Promise.resolve(this)

  ###*
  Accessor for RubicSettings

  @property {Object} settings
  @readOnly
  ###
  @getter "settings", -> @_settings

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
  Inter-process call with Promise

  @private
  @method _promisifiedCall
  @param {string} channel
    Channel string
  @param {Object} ...args
    Arguments
  @return {Promise|Object}
    Promise object with results
  ###
  _promisifiedCall: (channel, args...) ->
    id = Math.random().toString(36).substring(2)
    return new Promise((resolve, reject) =>
      @_requests[id] = {resolve, reject}
      @send(channel, id, args...)
    )

