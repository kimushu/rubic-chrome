# Pre dependencies
JSONable = require("./jsonable")
I18n = require("./i18n")
Preferences = require("./preferences")
App = require("./app")
Board = null

# (From library.min.js)
# GitHub

CAT_OWNER = "kimushu"
CAT_REPO  = "rubic-catalog"
CAT_REF   = "heads/master"
CAT_PATH  = "catalog.json"

AUTO_UPDATE_PERIOD = 12 * 60 * 60 * 1000  # 1 update per 12 hours

###*
@class Catalog
  Catalog data container class
  (One Catalog instance retains the information of one board)
###
class Catalog extends JSONable
  Catalog.jsonable()

  #--------------------------------------------------------------------------------
  # Public properties
  #

  @property("lastModified", get: -> @_lastModified)
  @property("lastFetched", get: -> @_lastFetched)
  @property("rubicVersion", get: -> @_rubicVersion)
  @property("engines", get: -> @_engines)

  window.Catalog = Catalog

  #--------------------------------------------------------------------------------
  # Public methods
  #

  ###*
  @static
  @method
    Update catalogs
  @return {boolean} [forceUpdate=false]
    Force update if true
  @return {Promise}
    Promise object
  ###
  @update: (forceUpdate = false) ->
    Board or= require("./board")
    key = "catalog.lastFetched"
    return Promise.resolve(
    ).then(=>
      return Preferences.get({"#{key}": 0})
    ).then((value) =>
      diff = Date.now() - value[key]
      if (diff < AUTO_UPDATE_PERIOD) and (not forceUpdate)
        console.log("Update catalog has been skipped")  # TODO
        return  # Last PromiseValue

      repo = new GitHub().getRepo(CAT_OWNER, CAT_REPO)
      timestamp = null
      return repo.getContents(CAT_REF, CAT_PATH, true).then((response) =>
        timestamp = Date.now()
        return Preferences.set({"#{key}": timestamp}).then(=>
          return response.data
        )
      ).then((catalogs) =>
        boards = []
        for boardClass in Board.subclasses
          name = boardClass.name
          source = catalogs[name]
          boards.push({name: name, source: source}) if source?
        return boards
      ).then((boards) =>
        lastError = null
        return boards.reduce(
          (promise, board) =>
            return promise.then(=>
              return @_mergeBoardCatalog(board.name, board.source, timestamp)
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
  @static
  @method
    Load catalog of the specific board
  @param {string} boardName
    The name of board to load catalog
  @param {boolean} [tryUpdate=false]
    Try update if true
  @param {boolean} [forceUpdate=false]
    Force update if true
  @return {Promise}
    Promise object
  @return {Catalog} return.PromiseValue
    The instance of Catalog
  ###
  @load: (boardName, tryUpdate = true, forceUpdate = false) ->
    key = "catalog.#{boardName}"
    return Promise.resolve(
    ).then(=>
      return unless tryUpdate
      return @update(forceUpdate)
    ).then(=>
      return Preferences.get({"#{key}": {}})
    ).then((value) =>
      return new Catalog(value[key])  # Last PromiseValue
    ) # return Promise.resolve().then()...
    return

  #--------------------------------------------------------------------------------
  # Private methods
  #

  ###*
  @private
  @method constructor
    Constructor of Catalog class
  @param {Object} src
    JSON object
  ###
  constructor: (src) ->
    @_lastModified = src.lastModified
    @_lastFetched  = src.lastFetched
    @_rubicVersion = src.rubicVersion
    @_engines      = []
    for esrc in (src.engines or [])
      edest = {}
      edest.name      = I18n.parseJSON(esrc.name)
      edest.className = esrc.className
      edest.id        = esrc.id
      edest.beta      = !!esrc.beta
      edest.obsolete  = !!esrc.obsolete
      edest.replaced  = esrc.replaced
      edest.firmwares = []
      for fsrc in (esrc.firmwares or [])
        fdest = {}
        fdest.name         = I18n.parseJSON(fsrc.name)
        fdest.id           = fsrc.id
        fdest.assets       = fsrc.assets
        fdest.rubicVersion = fsrc.rubicVersion
        fdest.beta         = !!fsrc.beta
        fdest.obsolete     = !!fsrc.obsolete
        fdest.replaced     = fsrc.replaced
        edest.firmwares.push(fdest)
      @_engines.push(edest)
    return

  ###*
  @private
  @method
    Merge board catalog into local cache
  @param {string} boardName
    Name of the board
  @param {Object} src
    Catalog info
  @param {number} timestamp
    Timestamp of receiving catalog info
  @return {Promise}
    Promise object
  ###
  @_mergeBoardCatalog: (boardName, src, timestamp) ->
    pname = "catalog.#{boardName}"
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

module.exports = Catalog
