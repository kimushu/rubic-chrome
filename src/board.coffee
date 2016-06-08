# Pre dependencies
JSONable = require("./jsonable")
App = require("./app")
Preferences = require("./preferences")
# From library.min.js
# JSZip
# GitHub

CAT_OWNER = "kimushu"
CAT_REPO  = "rubic-catalog"
CAT_REF   = "heads/master"
CAT_PATH  = "catalog.json"

AUTO_UPDATE_PERIOD = 12 * 60 * 60 * 1000  # 1 update per 12 hours

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
  @property {string} engineId
    The ID of engine
  ###
  @property("engineId",
    get: -> @_engineId
    set: (v) -> @_engineId = v
  )

  window.Board = Board

  #--------------------------------------------------------------------------------
  # Public methods
  #

  ###*
  @static
  @method
    Update catalog for boards
  @param {string} [className=null]
    The name of board to be updated (if null, update all boards)
  @param {boolean} [force=false]
    Force update
  @return {Promise}
    Promise object
  @return {Object} return.PromiseValue
    Update information
  @return {boolean} return.PromiseValue.succeeded
    Update succeeded or not
  @return {number} return.PromiseValue.timestamp
    Timestamp of latest update
  ###
  @updateCatalog: (className = null, force = false) ->
    return Promise.resolve(
    ).then(=>
      return Preferences.get({"catalog.lastFetched": 0})
    ).then((value) =>
      diff = Date.now() - value["catalog.lastFetched"]
      if !force and diff < AUTO_UPDATE_PERIOD
        console.log("Update catalog has been skipped")
        return  # Last PromiseValue

      repo = new GitHub().getRepo(CAT_OWNER, CAT_REPO)
      timestamp = null
      return repo.getContents(CAT_REF, CAT_PATH, true).then((response) =>
        timestamp = Date.now()
        return Preferences.set({"catalog.lastFetched": timestamp}).then(=>
          return response.data
        )
      ).then((catalog) =>
        boards = []
        for boardClass in Board.subclasses
          name = boardClass.name
          continue if className? and name != className
          source = catalog[name]
          boards.push({class: boardClass, source: source}) if source?
        return boards
      ).then((boards) =>
        lastError = null
        return boards.reduce(
          (promise, board) =>
            return promise.then(=>
              return @_mergeBoardCatalog(board.class, board.source, timestamp)
            ).catch((error) =>
              lastError = error
              return
            )
          Promise.resolve()
        ).then(=>
          return Promise.reject(lastError) if lastError?
          return  # Last PromiseValue
        )
      ) # return repo.getContents().then()...
    ) # return Promise.resolve().then()...

  ###*
  @method
    Enumerate ID of engines
  @param {boolean} [update=false]
    Try update from web if true
  @return {Promise}
    Promise object
  @return {string[]} return.PromiseValue
    Array of engine IDs
  ###
  enumEngines: (update = false) ->
    return Promise.resolve(
    ).then(=>
      return unless update
      return Board.updateCatalog(@constructor.name)
    ).then(=>
      return Preferences.get({"catalog.#{@constructor.name}": {}})
    ).then((cat) =>
      result = []
      # cat.rubicVersion
      result.push(e.id) for e in cat.engines
      return result # Last PromiseValue
    ) # return Promise.resolve().then()...

  ###*
  @template
  ###

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
    @_connected = false
    @_variation = obj?.variation
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
      variation     : @_variation
    })

  #--------------------------------------------------------------------------------
  # Private methods
  #

  ###*
  @private
  @method
    Merge board catalog into local cache
  @param {Function} boardClass
    Constructor of board subclass
  @param {Object} src
    Catalog info
  @param {number} timestamp
    Timestamp of receiving catalog info
  @return {Promise}
    Promise object
  ###
  @_mergeBoardCatalog: (boardClass, src, timestamp) ->
    pname = "catalog.#{boardClass.name}"
    return Promise.resolve(
    ).then(=>
      return Preferences.get(pname)
    ).then((read) =>
      dest = read or {}
      return unless App.versionCheck(src.rubicVersion)
      return if src.lastModified < (dest.lastFetched or 0)
      return dest
    ).then((dest) =>
      return unless dest?
      return dest if (e = src.engines) instanceof Array
      return I18n.rejectPromise("") unless e.path?
      repo = new GitHub().getRepo(e.owner or CAT_OWNER, e.repo or CAT_REPO)
      return repo.getContents(e.ref or CAT_REF, e.path).then((response) =>
        timestamp = Date.now()
        src.engines = response.data
        return dest
      )
    ).then((dest) =>
      return unless dest?
      dest = src
      dest.lastFetched = timestamp
      return Preferences.set({"#{pname}": dest}).then(=>
        return
      )
    ) # return Promise.resolve().then()...

module.exports = Board
