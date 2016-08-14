# Pre dependencies
# (none)

class Preferences
  unless (CHROME_STORAGE = chrome.storage?.local)?
    console.warn("chrome.storage.local is provided as an emulation module using webkit TEMPORARY FileSystem.")

  #--------------------------------------------------------------------------------
  # Private variables / constants
  #

  KEY_DEVFILT = "device_filter"
  KEY_LOGVERB = "log_verbosity"
  _cache = {"#{KEY_DEVFILT}": true, "#{KEY_LOGVERB}": 1}  # Default values for debugging
  _os = null

  #--------------------------------------------------------------------------------
  # Public properties
  #

  Object.defineProperties(this, {
    deviceFilter:
      get: -> _cache[KEY_DEVFILT]
    logVerbosity:
      get: -> _cache[KEY_LOGVERB]
  })

  Object.defineProperty(this, "os", get: ->
    return _os if _os?
    ua = window.navigator.userAgent
    if ua.includes("(Windows")
      return (_os = "win")
    if ua.includes("(Mac")
      return (_os = "mac")
    return (_os = "unknown")
  )

  #--------------------------------------------------------------------------------
  # Public methods
  #

  ###*
  @static
  @method
    Get preference item(s)
  @param {string[]/Object} keys
    Array of key string / Key:default-value map
  @return {Promise}
    Promise object
  @return {Object} return.PromiseValue
    Read value
  ###
  @get: (keys) ->
    return new Promise((resolve, reject) =>
      # (Chrome App) chrome.storage
      CHROME_STORAGE.get(keys, (items) =>
        return resolve(items) unless (e = chrome.runtime.lastError)?
        return reject(e)
      )
    ) if CHROME_STORAGE?

    # (Browser emulation) webkit FileSystem
    if !keys
      return Promise.reject("Listing is not supported in chrome.storage emulation")
    else if typeof(keys) == "string"
      items = {"#{keys}": undefined}
    else if keys instanceof Array
      items = {}
      items[key] = undefined for key in keys
    else
      items = keys
    keys = (key for key, value of items)
    return @_getFs(
    ).then((fs) =>
      return new Promise((resolve, reject) =>
        fs.root.getDirectory("chrome.storage.local", {create: true}, resolve, reject)
      )
    ).then((dirEntry) =>
      return keys.reduce(
        (promise, key) =>
          return promise.then(=>
            return new Promise((resolve, reject) =>
              dirEntry.getFile(key, {create: false}, resolve, reject)
            )
          ).then((fileEntry) =>
            return new Promise((resolve, reject) =>
              fileEntry.file(resolve, reject)
            )
          ).then((file) =>
            return new Promise((resolve, reject) =>
              reader = new FileReader()
              reader.onload = => resolve(reader.result)
              reader.onerror = reject
              reader.readAsText(file)
            )
          ).then((text) =>
            items[key] = JSON.parse(text)
            return
          ).catch((error) =>
            return if error.name == "NotFoundError"
            return Promise.reject(error)
          ) # return promise.then()...
        Promise.resolve()
      ) # return keys.reduce()
    ).then(=>
      return items  # Last PromiseValue
    ) # return @_getFs().then()...

  ###*
  @static
  @method
    Initialize cache
  @param {Object} [items]
    Key:value map
  @return {Promise/undefined}
    Promise object if items omitted
  ###
  @initCache: (items) ->
    if items?
      # Sync call
      v = items[k = KEY_DEVFILT]
      _cache[k] = !!v if v?
      v = items[k = KEY_LOGVERB]
      _cache[k] = parseInt(v) or 0 if v?
      return

    # Async call
    # (Default values for production)
    return @get({"#{KEY_DEVFILT}": true, "#{KEY_LOGVERB}": 0}).then((items) =>
      @initCache(items)
      return  # Last PromiseValue
    )

  ###*
  @static
  @method
    Set preference item(s)
  @param {Object} items
    Key:value map
  @return {Promise}
    Promise object
  @return {undefined} return.PromiseValue
  ###
  @set: (items) ->
    @initCache(items or {})
    return new Promise((resolve, reject) =>
      # (Chrome App) chrome.storage
      CHROME_STORAGE.set(items, =>
        return resolve() unless (e = chrome.runtime.lastError)?
        return reject(e)
      )
    ) if CHROME_STORAGE?

    # (Browser emulation) webkit FileSystem
    keys = (key for key, value of items)
    return @_getFs(
    ).then((fs) =>
      return new Promise((resolve, reject) =>
        fs.root.getDirectory("chrome.storage.local", {create: true}, resolve, reject)
      )
    ).then((dirEntry) =>
      return keys.reduce(
        (promise, key) =>
          return promise.then(=>
            return new Promise((resolve, reject) =>
              dirEntry.getFile(key, {create: true}, resolve, reject)
            )
          ).then((fileEntry) =>
            return Promise.resolve(
            ).then(=>
              return new Promise((resolve, reject) =>
                fileEntry.createWriter(resolve, reject)
              )
            ).then((fileWriter) =>
              return new Promise((resolve, reject) =>
                fileWriter.onwriteend = resolve
                fileWriter.onerror = reject
                fileWriter.truncate(0)
              )
            ).then(=>
              return new Promise((resolve, reject) =>
                fileEntry.createWriter(resolve, reject)
              )
            ).then((fileWriter) =>
              return new Promise((resolve, reject) =>
                fileWriter.onwriteend = resolve
                fileWriter.onerror = reject
                fileWriter.write(new Blob([JSON.stringify(items[key])]))
              )
            )
          )
        Promise.resolve()
      ) # return keys.reduce()
    ).then(=>
      return  # Last PromiseValue
    ) # return @_getFs().then()...

  ###*
  @static
  @method
    Clear all preference items
  @return {Promise}
    Promise object
  @return {undefined} return.PromiseValue
  ###
  @clear: ->
    return new Promise((resolve, reject) =>
      # (Chrome App) chrome.storage
      CHROME_STORAGE.clear(=>
        return resolve() unless (e = chrome.runtime.lastError)?
        return reject(e)
      )
    ) if CHROME_STORAGE?

    # (Browser emulation) webkit FileSystem
    return @_getFs(
    ).then((fs) =>
      return new Promise((resolve, reject) =>
        fs.root.getDirectory("chrome.storage.local", {create: false}, resolve, reject)
      )
    ).then((dirEntry) =>
      return new Promise((resolve, reject) =>
        dirEntry.removeRecursively(resolve, reject)
      )
    ).then(=>
      return  # Last PromiseValue
    ).catch((error) =>
      return if error.name == "NotFoundError"
      return Promise.reject(error)
    ) # return @_getFs().then()...

  #--------------------------------------------------------------------------------
  # Private methods
  #

  ###*
  @private
  @static
  @method
    Get webkit TEMPORARY FileSystem
  @return {Promise}
    Promise object
  @return {Object} return.PromiseValue
    FileSystem object
  ###
  @_getFs: ->
    return Promise.resolve(@_fs) if @_fs?
    return new Promise((resolve, reject) =>
      window.webkitRequestFileSystem(
        window.TEMPORARY
        5 * 1024 * 1024
        (fs) => return resolve(@_fs = fs)
        reject
      )
    )

module.exports = Preferences

# Post dependencies
# (none)
