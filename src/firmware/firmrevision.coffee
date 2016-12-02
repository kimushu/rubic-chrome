"use strict"
# Pre dependencies
JSONable = require("util/jsonable")
require("util/primitive")

###*
@class FirmRevision
  Revision of firmware (Model)
@extends JSONable
###
module.exports = class FirmRevision extends JSONable
  FirmRevision.jsonable()

  #--------------------------------------------------------------------------------
  # Public properties
  #

  ###*
  @property {string} id
    ID of this firmware revision
  @readonly
  ###
  @property("id", get: -> @_id)

  ###*
  @property {I18n} friendlyName
    The name of firmware
  @readonly
  ###
  @property("friendlyName", get: -> @_friendlyName)

  ###*
  @property {string} rubicVersion
    Supported Rubic version
  @readonly
  ###
  @property("rubicVersion", get: -> @_rubicVersion)

  ###*
  @property {number} lastModified
    Timestamp of last modified date (in milliseconds from epoch, UTC)
  @readonly
  ###
  @property("lastModified", get: -> @_lastModified)

  ###*
  @property {Function[]} builderClasses
    Array of supported builders
  @readonly
  ###
  @property("builderClasses",
    get: -> Object.freeze(c for c in @_builderClasses)
  )

  ###*
  @property {RegExp[]} executables
    Array of executable items
  @readonly
  ###
  @property("executables",
    get: -> Object.freeze(e for e in @_executables)
  )

  ###*
  @property {boolean} beta
    Is a beta feature?
  @readonly
  ###
  @property("beta", get: -> @_beta)

  ###*
  @property {boolean} obsolete
    Is an obsolete feature?
  @readonly
  ###
  @property("obsolete", get: -> @_obsolete)

  ###*
  @property {string[]} assetNames
    List of asset files
  @readonly
  ###
  @property("assetNames", get: -> (name for name, url of @_assets))

  ###*
  @property {Object} boardSpecific
    Get board specific information
  @readonly
  ###
  @property("boardSpecific", get: -> @_boardSpecific)

  #--------------------------------------------------------------------------------
  # Private properties
  #

  ###*
  @private
  @property {string} _key
    Asset key
  @readonly
  ###
  @property("_key", get: -> "assets.#{@_id}")

  #--------------------------------------------------------------------------------
  # Public methods
  #

  ###*
  @method
    Check cache availability
  @return {Promise}
    Promise object
  @return {boolean} return.PromiseValue
    true if cached
  ###
  checkCacheAvailability: ->
    return Promise.resolve(true) if @_cache
    key = @_key
    return Preferences.get(key).then((values) =>
      return !!values[key]
    )

  ###*
  @method
    Download all assets
  @param {boolean} force
    Force download
  @return {Promise}
    Promise object
  ###
  download: (force = false) ->
    return Promise.resolve() if @_cache? and !force
    zip = new JsZip()
    key = @_key
    return Promise.resolve(
    ).then(=>
      return if force
      return {"#{key}": @_cache} if @_cache?
      return Preferences.get(key)
    ).then((values) =>
      cache = values?[key]
      return if cache?
      return @assetNames.reduce(
        (promise, name) =>
          return promise.then(=>
            url = @_assets[name]
            return XhrPromise.getAsArrayBuffer(url)
          ).then((xhr) =>
            zip.file(name, xhr.response, {compression: "DEFLATE"})
          )
        Promise.resolve()
      ).then(=>
        return zip.generateAsync({type: "base64"})
      ).then((cache) =>
        @_cache = cache
        return Preferences.set({"#{key}": cache})
      ) # return @assetNames.reduce().then()...
    ).then(=>
      return  # Last PromiseValue
    ) # return Promise.resolve().then()...

  ###*
  @method constructor
    Constructor of FirmRevision class
  @param {Object} obj
    JSON object
  ###
  constructor: (obj = {}) ->
    @_id              = obj.id?.toString()
    @_friendlyName    = I18n.parseJSON(obj.friendlyName)
    @_rubicVersion    = obj.rubicVersion?.toString()
    @_lastModified    = parseInt(obj.lastModified)
    @_builderClasses  =
      (Builder.subclasses.find((c) => c.name == name) for name in obj.builderClasses or [])
    @_executables     = (new RegExp(e[0], e[1]) for e in obj.executables or [])
    @_beta            = !!obj.beta
    @_obsolete        = !!obj.obsolete
    @_assets          = obj.assets or {}
    @_boardSpecific   = obj.boardSpecific or {}
    return

  ###*
  @method
    Convert to JSON object
  @return {Object}
  ###
  toJSON: ->
    return super().extends({
      id              : @_id
      friendlyName    : @_friendlyName
      rubicVersion    : @_rubicVersion
      lastModified    : @_lastModified
      builderClasses  : (cls.name for cls in @_builderClasses)
      executables     : ([e.source, e.flags] for e in @_executables)
      beta            : @_beta
      obsolete        : @_obsolete
      assets          : @_assets
      boardSpecific   : @_boardSpecific
    })

# Post dependencies
I18n = require("util/i18n")
XhrPromise = require("util/xhrpromise")
JsZip = global.Libs.JsZip
Preferences = require("app/preferences")
Builder = require("builder/builder")
