"use strict"
require("../../util/primitive")

###*
Load and store user preferences

@class RubicSettings
###
module.exports =
class RubicSettings

  constructor: (options) ->
    console.log("new RubicSettings()")
    Settings = Object.getPrototypeOf(require("electron-settings")).constructor
    @_settings = new Settings()
    @_barrier = Promise.resolve()
    return

  ###*
  Setting file path

  @property filePath
  @type string
  @readOnly
  ###
  @getter "filePath", -> @_settings.getSettingsFilePath()

  ###*
  Get values

  @method get
  @param {Object|string} map
    Pair of key and default value / key name without default value
  @return {Promise|Object}
    Promise object with map
  ###
  get: (map) ->
    if Object::toString.call(map) == "[object String]"
      map = {"#{map}": undefined}
    result = {}
    @_barrier = Object.keys(map).reduce(
      (promise, key) =>
        return promise.then(=>
          return @_settings.get(key)
        ).then((value) =>
          if value == undefined
            result[key] = map[key]
          else
            result[key] = value
          return
        )
      @_barrier
    ).then(=>
      return result # Last PromiseValue
    )
    return @_barrier

  ###*
  Set or delete values

  @method set
  @param {Object} map
    Pair of key and value (if value is undefined, key will be deleted)
  @return {Promise}
    Promise object
  ###
  set: (map) ->
    @_barrier = Object.keys(map).reduce(
      (promise, key) =>
        return promise.then(=>
          if map[key] == undefined
            return @_settings.delete(key)
          else
            return @_settings.set(key, map[key])
        )
      @_barrier
    ).then(=>
      return  # Last PromiseValue
    )
    return @_barrier

  ###*
  Clear all settings

  @method clear
  @return {Promise}
    Promise object
  ###
  clear: ->
    @_barrier = @_barrier.then(=>
      return @_settings.clear()
    ).then(=>
      return  # Last PromiseValue
    )
    return @_barrier

  ###*
  Start listener for access from renderer-process

  @method listen
  @return {undefined}
  ###
  startListener: ->
    {ipcMain} = require("electron")
    ipcMain.on("settings-call", (event, id, method, args...) =>
      @[method](args...).then((result) =>
        event.sender.send("settings-reply", id, {result})
      ).catch((error) =>
        event.sender.send("settings-reply", id, {error})
      )
    )
    return

  ###*
  Create a RubicSettings instance

  @static
  @method open
  @param {Object} options
    Options
  @return {Promise|RubicSettings}
    Promise object with instance
  ###
  @open: (options) ->
    return new RubicSettings(options)._initialize(options)

  ###*
  Initialize instance

  @private
  @method _initialize
  @param {Object} options
    Options
  @return {Promise|RubicSettings}
    Promise object with instance
  ###
  _initialize: (options) ->
    return Promise.resolve(this)

