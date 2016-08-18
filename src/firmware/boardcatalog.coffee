"use strict"
# Pre dependencies
require("util/primitive")

###*
@class Catalog
  Catalog data container class
###
module.exports = class BoardCatalog
  null

  #--------------------------------------------------------------------------------
  # Public properties
  #

  ###*
  @property {number} lastModified
    Timestamp of last modified date (in milliseconds from epoch, UTC)
  @readonly
  ###
  @property("lastModified", get: -> @_cache.lastFetched)

  ###*
  @property {number} lastFetched
    Timestamp of last fetched date (in milliseconds from epoch, UTC)
  @readonly
  ###
  @property("lastFetched", get: -> @_cache.lastFetched)

  ###*
  @property {Function[]} boardClasses
    List of board classes in catalog
  @readonly
  ###
  @property("boardClasses", get: -> c for c in @_boardClasses)

  #--------------------------------------------------------------------------------
  # Public methods
  #

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
  @load: (tryUpdate = true, forceUpdate = false) ->
    return Promise.resolve(
    ).then(=>
      return CatalogCache.load()
    ).then((cache) =>
      return new this(cache)
    ).then((instance) =>
      return instance unless tryUpdate
      return instance.update(forceUpdate)
    ) # return Promise.resolve().then()...

  ###*
  @method
    Update catalog cache
  @param {boolean} [force=false]
    Force update (Ignore timestamp)
  @return {Promise}
    Promise object
  @return {BoardCatalog} return.PromiseValue
    this
  ###
  update: (force) ->
    return Promise.resolve(
    ).then(=>
      return @_cache.update(force)
    ).then((updated) =>
      App.info("Catalog update has been skipped") unless updated
      @_reloadCache()
      return this
    ) # return Promise.resolve().then()...

  ###*
  @method
    Get board description
  @param {Function} boardClass
    Board class constructor
  @return {I18n}
    Description
  ###
  getDescription: (boardClass) ->
    desc = @_cache.getData(boardClass.id)?.description
    return new I18n("") unless desc?
    return I18n.parseJSON(desc)

  ###*
  @method
    Get firmware catalog
  @param {Function} boardClass
    Board class constructor
  @return {FirmCatalog}
    FirmCatalog instance
  ###
  getFirmCatalog: (boardClass) ->
    return new FirmCatalog(boardClass, @_cache.getData(boardClass.id)?.content)

  #--------------------------------------------------------------------------------
  # Private methods
  #

  ###*
  @private
  @method constructor
    Constructor of BoardCatalog class
  @param {CatalogCache} _cache
    CatalogCache instance
  ###
  constructor: (@_cache) ->
    @_reloadCache()
    return

  ###*
  @private
  @method
    Reload cache
  ###
  _reloadCache: ->
    @_boardClasses = []
    for id in @_cache.boards
      found = null
      for c in Board.subclasses
        if c.id == id
          found = c
          break
      if found?
        @_boardClasses.push(found)
      else
        App.error("A Board class (id:#{id}) is not found")
    return

# Post dependencies
App = require("app")
Board = require("board/board")
CatalogCache = require("firmware/catalogcache")
I18n = require("util/i18n")
FirmCatalog = require("firmware/firmcatalog")
