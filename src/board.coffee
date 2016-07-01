# Pre dependencies
JSONable = require("./jsonable")
EventTarget = require("./eventtarget")
I18n = require("./i18n")
NamedLink = require("./namedlink")
Catalog = null

###*
@class Board
  Base class for embedded boards (Model)
@extends JSONable
###
class Board extends JSONable
  null

  #--------------------------------------------------------------------------------
  # Public properties
  #

  ###*
  @property {boolean} connected
  ###
  @property("connected", get: -> @_connected)

  ###*
  @property {NamedLink} engineLink
    The link to Engine object
  @readonly
  ###
  @property("engineLink", get: -> @_engineLink)

  ###*
  @property {NamedLink} firmwareLink
    The link to Firmware object
  ###
  @property("firmwareLink", get: -> @_firmwareLink)

  #--------------------------------------------------------------------------------
  # Event listeners
  #

  ###*
  @event onChange
    Changed event target
  ###
  @property("onChange", get: -> @_onChange)

  ###*
  @event onConnected
    Connected event target
  ###
  @property("onConnected", get: -> @_onConnected)

  ###*
  @event onDisconnected
    Disconnected event target
  ###
  @property("onDisconnected", get: -> @_onDisconnected)

  #--------------------------------------------------------------------------------
  # Public methods
  #

  ###*
  @method
    Get catalog
  @param {boolean} [tryUpdate=false]
    Try update from web if true
  @return {Promise}
    Promise object
  @return {Catalog} return.PromiseValue
    Catalog data
  ###
  getCatalog: (tryUpdate = false) ->
    Catalog or= require("./catalog")
    return Promise.resolve(
    ).then(=>
      return Catalog.load(@constructor.name, true) if tryUpdate
      return @_catalog if @_catalog?
      return I18n.rejectPromise("Lack_of_catalog_cache")
    ).then((catalog) =>
      return (@_catalog = catalog)  # Last PromiseValue
    ) # return Promise.resolve().then()...

  ###*
  @template
  @method
    Get list of pins
  @return {Object}
    Pin definition
  @return {Object} return.left
    Left side definition
  @return {Object} return.right
    Right side definition
  @return {string[]/I18n[]} return.aliases
    Name of alias groups
  ###
  getPinList: ->
    return {}

  ###*
  @template
  @method
    Enumerate boards
  @return {Promise}
    Promise object
  @return {Object[]} return.PromiseValue
    Array of board information {friendlyName: "name for UI", path: "path"}
  ###
  enumerate: ->
    return Promise.reject(Error("Pure method"))

  ###*
  @template
  @method
    Connect to board
  @param {string} path
    Path of the board
  @param {Function} onDisconnected
    Callback for disconnect detection
  @return {Promise}
    Promise object
  @return {undefined} return.PromiseValue
  ###
  connect: (path, onDisconnected) ->
    return Promise.reject(Error("Pure method"))

  ###*
  @template
  @method
    Disconnect from board
  @return {Promise}
    Promise object
  @return {undefined} return.PromiseValue
  ###
  disconnect: ->
    return Promise.reject(Error("Pure method"))

  ###*
  @template
  @method
    Get list of storages
  @return {Promise}
    Promise object
  @return {string[]} return.PromiseValue
  ###
  getStorages: ->
    return Promise.reject(Error("Pure method"))

  ###*
  @template
  @method
    Request pseudo filesystem
  @return {Promise}
    Promise object
  @return {AsyncFs} return.PromiseValue
    File system object
  ###
  requestFileSystem: ->
    return Promise.reject(Error("Pure method"))

  ###*
  @template
  @method
    Request console
  @return {Promise}
    Promise object
  ###
  requestConsole: ->
    return Promise.reject(Error("Pure method"))

  ###*
  @template
  @method
    Start sketch
  @param {function(boolean):undefined} onFinished
    Callback for finish with result
  @return {Promise}
    Promise object
  ###
  startSketch: (onFinished) ->
    return Promise.reject(Error("Pure method"))

  ###*
  @template
  @method
    Stop sketch
  @return {Promise}
    Promise object
  ###
  stopSketch: ->
    return Promise.reject(Error("Pure method"))

  #--------------------------------------------------------------------------------
  # Protected methods
  #

  ###*
  @method constructor
    Constructor of Board class
  @param {Object} obj
    JSON object
  ###
  constructor: (obj) ->
    super(obj)
    @_engineLink    = NamedLink.parseJSON(obj.engineLink)
    @_firmwareLink  = NamedLink.parseJSON(obj.firmwareLink)
    @_connected     = false
    @_onChange      = new EventTarget()
    return

  ###*
  @method
    Convert to JSON object
  @return {Object}
  ###
  toJSON: ->
    return super().extends({
      friendlyName  : @constructor.friendlyName
      rubicVersion  : @constructor.rubicVersion
      engineLink    : @_engineLink
      firmwareLink  : @_firmwareLink
    })

module.exports = Board
