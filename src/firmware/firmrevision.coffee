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
  @property {Object} engineOptions
    Engine options
  @readonly
  ###
  @property("engineOptions", get: ->
    r = {}
    r[k] = v for k, v of @_engineOptions
    return r
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
  @property {string[]} assets
    List of asset files
  @readonly
  ###
  @property("assets", get: -> (name for name, url of @_assets))

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
  findCache: ->
    return Promise.resolve(true) if @_cache
    key = @_key
    return Preferences(key).then((values) =>
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
      return @_assets.reduce(
        (promise, name) =>
          return promise.then(=>
            return XhrPromise.getAsArrayBuffer(@_assets[path])
          ).then((xhr) =>
            zip.file(name, xhr.response, {compression: "DEFLATE"})
          )
        Promise.resolve()
      ).then(=>
        return zip.generateAsync({type: "base64"})
      ).then((cache) =>
        @_cache = cache
        return Preferences.set({"#{key}": cache})
      ) # return @assets.reduce().then()...
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
    @_id            = obj.id?.toString()
    @_friendlyName  = I18n.parseJSON(obj.friendlyName)
    @_rubicVersion  = obj.rubicVersion?.toString()
    @_lastModified  = parseInt(obj.lastModified)
    @_beta          = !!obj.beta
    @_obsolete      = !!obj.obsolete
    @_assets        = obj.assets
    return

  ###*
  @method
    Convert to JSON object
  @return {Object}
  ###
  toJSON: ->
    return super().extends({
      id            : @_id
      friendlyName  : @_friendlyName
      rubicVersion  : @_rubicVersion
      lastModified  : @_lastModified
      beta          : @_beta
      obsolete      : @_obsolete
      assets        : @_assets
    })

# Post dependencies
I18n = require("util/i18n")
XhrPromise = require("util/xhrpromise")
JsZip = global.Libs.JsZip
