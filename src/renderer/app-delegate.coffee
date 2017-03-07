"use strict"
require("../util/primitive")
{ipcRenderer} = require("electron")

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

    @send("delegate-ready")
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

