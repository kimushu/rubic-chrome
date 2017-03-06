"use strict"
require("../util/primitive")
Settings = Object.getPrototypeOf(require("electron-settings")).constructor

###*
Load and store user preferences

@class RubicSettings
###
module.exports =
class RubicSettings

  constructor: (options) ->
    console.log("new RubicSettings()")
    @_settings = new Settings()
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
    return Object.keys(map).reduce(
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
      Promise.resolve()
    ).then(=>
      return result # Last PromiseValue
    )

  ###*
  Set or delete values

  @method set
  @param {Object} map
    Pair of key and value (if value is undefined, key will be deleted)
  @return {Promise}
    Promise object
  ###
  set: (map) ->
    return Object.keys(map).reduce(
      (promise, key) =>
        return promise.then(=>
          if map[key] == undefined
            return @_settings.delete(key)
          else
            return @_settings.set(key, map[key])
        )
      Promise.resolve()
    ).then(=>
      return  # Last PromiseValue
    )

  ###*
  Clear all settings

  @method clear
  @return {Promise}
    Promise object
  ###
  clear: ->
    return @_settings.clear().then(=>
      return  # Last PromiseValue
    )

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

