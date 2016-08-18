"use strict"
# Pre dependencies
require("util/primitive")
require("util/map2json")

###*
@class CatalogCache
  Catalog cache manager
###
module.exports = class CatalogCache
  null

  #--------------------------------------------------------------------------------
  # Public properties
  #

  ###*
  @property {number} lastModified
    Timestamp of last modified date (in milliseconds from epoch, UTC)
  @readonly
  ###
  @property("lastModified", get: -> @_lastModified)

  ###*
  @property {number} lastFetched
    Timestamp of last fetched date (in milliseconds from epoch, UTC)
  @readonly
  ###
  @property("lastFetched", get: -> @_lastFetched)

  ###*
  @property {string[]} boards
    Array of board IDs
  @readonly
  ###
  @property("boards", get: ->
    result = []
    @_boards.forEach((value, key) =>
      result.push(key)
    )
    return result
  )

  #--------------------------------------------------------------------------------
  # Private variables / constants
  #

  CACHE_KEY   = "catalogCache"
  EXPIRE_MS   = 12 * 60 * 60 * 1000 # 12 hours
  ROOT_OWNER  = "kimushu"
  ROOT_REPO   = "rubic-catalog"
  ROOT_BRANCH = "master"
  ROOT_PATH   = "catalog.json"

  #--------------------------------------------------------------------------------
  # Public methods
  #

  ###*
  @static
  @method
    Generate instance by loading data from cache
  @return {Promise}
    Promise object
  @return {CatalogCache} return.PromiseValue
    Generated instance
  ###
  @load: ->
    return Promise.resolve(
    ).then(=>
      return Preferences.get(CACHE_KEY)
    ).then((values) =>
      return new this(values[CACHE_KEY])
    )

  ###*
  @method
    Get board cache data
  @param {string} boardId
    Board ID
  @return {Object}
    JSON object
  ###
  getData: (boardId) ->
    return @_boards.get("#{boardId}")

  ###*
  @method
    Update cache contents
  @param {boolean} [force=false]
    Force update (Ignore timestamp)
  @return {Promise}
    Promise object
  @return {boolean} updated
    Result (true:yes, false:skipped)
  ###
  update: (force = false) ->
    now = Date.now()
    return Promise.resolve(false) if !force and now < ((@_lastFetched or 0) + EXPIRE_MS)
    root = new GitHubFetcher(ROOT_OWNER, ROOT_REPO, ROOT_BRANCH)
    obj = null
    boards = new Map()
    return Promise.resolve(
    ).then(=>
      return root.getAsJSON(ROOT_PATH)
    ).then((data) =>
      obj = data
      return (obj.boards or []).reduce(
        (promise, b) =>
          v = b[1]
          boards.set("#{b[0]}", v)
          if v.content?
            v.lastFetched = now
            return promise
          return promise unless v.path?
          now2 = Date.now()
          return promise.then(=>
            fetch = new GitHubFetcher(
              v.owner or ROOT_OWNER
              v.repo or ROOT_REPO
              v.branch or ROOT_BRANCH
            )
            return fetch.getAsJSON(v.path)
          ).then((data) =>
            v.content = data
            v.content.lastFetched = now2
            return
          )
        Promise.resolve()
      )
    ).then(=>
      @_lastModified = obj.lastModified
      @_lastFetched = now
      @_boards = boards
      return @_store()
    ).then(=>
      return true # Last PromiseValue
    ) # return Promise.resolve().then()...

  #--------------------------------------------------------------------------------
  # Private methods
  #

  ###*
  @private
  @method constructor
    Constructor of CatalogCache class
  @param {Object} [obj={}]
    JSON object
  ###
  constructor: (obj = {}) ->
    @_lastModified = parseInt(obj.lastModified or 0)
    @_lastFetched = parseInt(obj.lastFetched or 0)
    @_boards = Map.fromJSON(obj.boards)
    return

  ###*
  @private
  @method
    Store data to cache
  @return {Promise}
    Promise object
  ###
  _store: ->
    obj = {
      lastModified: @_lastModified
      lastFetched: @_lastFetched
      boards: @_boards.toJSON()
    }
    return Preferences.set({"#{CACHE_KEY}": obj})

# Post dependencies
Preferences = require("preferences")
GitHubFetcher = require("util/githubfetcher")
