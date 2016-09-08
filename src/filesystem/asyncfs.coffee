"use strict"
# Pre dependencies
UnJSONable = require("util/unjsonable")

###*
@class AsyncFs
  Asynchronous file system like fs module in Node.js
@extends UnJSONable
###
module.exports = class AsyncFs extends UnJSONable
  null

  #--------------------------------------------------------------------------------
  # Original properties
  #

  ###*
  @property {string} name
    The name of directory
  @readonly
  ###
  @property("name", get: -> @getNameImpl())

  ###*
  @property {string} fsType
    Filesystem type identifier
  @readonly
  ###
  @property("fsType", get: -> @_fsType)

  ###*
  @static
  @property {string} TEMPORARY
    Filesystem type identifier for temporary storage
  @readonly
  ###
  @classProperty("TEMPORARY", value: "TEMPORARY")

  ###*
  @static
  @property {string} LOCAL
    Filesystem type identifier for temporary storage
  @readonly
  ###
  @classProperty("LOCAL", value: "LOCAL")

  ###*
  @static
  @property {string} BOARD_INTERNAL
    Filesystem type identifier for board internal storage
  @readonly
  ###
  @classProperty("BOARD_INTERNAL", value: "BOARD_INTERNAL")

  #--------------------------------------------------------------------------------
  # Private variables / constants
  #

  @_retainable: []

  invokeCallback = (callback, promise) ->
    promise.then((value) ->
      callback(null, value)
      return
    ).catch((error) ->
      callback(error)
      return
    )
    return

  SEP         = "/"
  SEP_RE      = /\/+/
  SEP_LAST_RE = /\/+$/

  #--------------------------------------------------------------------------------
  # Node.js compatible methods
  #

  ###*
  @method
    Make a new directory
  @param {string} path
    Directory path
  @param {number} [mode]
    Mode (permissions)
  @param {function(Error/null):undefined} [callback]
    Callback function when Promise is not used
  @return {undefined/Promise}
    Promise object when callback is omitted
  ###
  mkdir: (path, mode = 0o777, callback) ->
    if typeof(mode) == "function"
      callback = mode
      mode = 0o777
    return invokeCallback(callback, @mkdir(path, mode)) if callback?
    path = path.split(SEP_RE).join(SEP).replace(SEP_LAST_RE, "")
    return @mkdirImpl(path, mode)

  ###*
  @method
    Read contents from file
  @param {string} file
    File path
  @param {Object/string} [options]
    Options
  @param {function(Error/null,Object):undefined} [callback]
    Callback function when Promise is not used
  @return {undefined/Promise}
    Promise object when callback is omitted
  ###
  readFile: (file, options = {flag: "r"}, callback) ->
    if typeof(options) == "function"
      callback = options
      options = null
    return invokeCallback(callback, @readFile(file, options)) if callback?
    file = file.split(SEP_RE).join(SEP)
    options = {encoding: options} if typeof(options) == "string"
    return @readFileImpl(file, options)

  ###*
  @method
    Remove a directory
  @param {string} path
    Directory path
  @param {function(Error/null):undefined} [callback]
    Callback function when Promise is not used
  @return {undefined/Promise}
    Promise object when callback is omitted
  ###
  rmdir: (path, callback) ->
    return invokeCallback(callback, @rmdir(path)) if callback?
    path = path.split(SEP_RE).join(SEP).replace(SEP_LAST_RE, "")
    return @rmdirImpl(path)

  ###*
  @method
    Write contents to file
  @param {string} file
    File path
  @param {ArrayBuffer/string} data
    Data to write
  @param {Object/string} [options]
    Options
  @param {function(Error/null):undefined} [callback]
    Callback function when Promise is not used
  @return {undefined/Promise}
    Promise object when callback is omitted
  ###
  writeFile: (file, data, options = {mode: 0o666, flag: "w"}, callback) ->
    if typeof(options) == "function"
      callback = options
      options = null
    return invokeCallback(callback, @writeFile(file, data, options)) if callback?
    file = file.split(SEP_RE).join(SEP)
    options = {encoding: options} if typeof(options) == "string"
    return @writeFileImpl(file, data, options)

  ###*
  @method
    Unlink a file
  @param {string} path
    File path
  @param {function(Error/null):undefined} [callback]
    Callback function when Promise is not used
  @return {undefined/Promise}
    Promise object when callback is omitted
  ###
  unlink: (path, callback) ->
    return invokeCallback(callback, @unlink(path)) if callback?
    path = path.split(SEP_RE).join(SEP)
    return @unlinkImpl(path)

  #--------------------------------------------------------------------------------
  # Original methods
  #

  ###*
  @method
    Open directory as fs object
  @param {string} path
    File path
  @param {function(Error/null,AsyncFs):undefined} [callback]
    Callback function when Promise is not used
  @return {undefined/Promise}
    Promise object when callback is omitted
  @return {AsyncFs} return.PromiseValue
    New fs object for directory
  ###
  opendirfs: (path, callback) ->
    return invokeCallback(callback, @opendirfs(path)) if callback?
    path = path.split(SEP_RE).join(SEP)
    return @opendirfsImpl(path)

  ###*
  @method
    Retain filesystem
  @return {Promise}
    Promise object
  @return {Object} return.PromiseValue
    Object to describe retain information
  ###
  retainfs: ->
    return @retainfsImpl().then((obj) =>
      obj.__class__ = @constructor.name
      return Object.freeze(obj)
    )

  ###*
  @static
  @method
    Restore filesystem
  @param {Object} retainInfo
    Object to describe retain information
  @return {Promise}
    Promise object
  @return {AsyncFs} return.PromiseValue
    Restored filesystem object
  ###
  @restorefs: (retainInfo) ->
    name = retainInfo.__class__
    (return c.restorefs(retainInfo)) for c in @_retainable when c.name == name
    return Promise.reject(Error("No retainable filesystem: #{name}"))

  ###*
  @static
  @method
    Open temporary directory as fs object
  @param {function(Error/null,AsyncFs):undefined} [callback]
    Callback function when Promise is not used
  @return {undefined/Promise}
    Promise object when callback is omitted
  @return {AsyncFs} return.PromiseValue
    New fs object for directory
  ###
  @opentmpfs: (callback) ->
    return invokeCallback(callback, @opentmpfs()) if callback?
    return new Promise((resolve, reject) =>
      window.webkitRequestFileSystem(
        window.TEMPORARY
        5 * 1024 * 1024
        (fs) => resolve(new Html5Fs(fs.root, @TEMPORARY))
        reject
      )
    ) # return new Promise()

  ###*
  @static
  @method
    Choose file from local
  @param {boolean} [writable=false]
    Request writable file
  @param {function(Error/null,Object):undefined} [callback]
    Callback function when Promise is not used
  @return {undefined/Promise}
    Promise object when callback is omitted
  @return {Object} return.PromiseValue
    Information of chosen file
  @return {AsyncFs} return.PromiseValue.fs
    New fs object for chosen file
  @return {string} return.PromiseValue.name
    Name of chosen file
  ###
  @chooseFile: (writable, callback) ->
    return invokeCallback(callback, @chooseDirectory(writable)) if callback?
    writable = !!writable
    return new Promise((resolve, reject) =>
      chrome.fileSystem.chooseEntry(
        {type: if writable then "openWritableFile" else "openFile"}
        (entry) =>
          unless entry?
            error = chrome.runtime.lastError
            return reject(Error(error?.message or error))
          return resolve(entry)
      )
    ).then((entry) =>
      dummyDirEntry = {
        name: undefined
        getDirectory: (path, options, success, error) ->
          return error(new PseudoFileError("NOT_FOUND_ERR"))
        getFile: (path, options, success, error) ->
          return error(
            new PseudoFileError("NOT_FOUND_ERR")
          ) unless path == entry.name
          return error(
            new PseudoFileError("NO_MODIFICATION_ALLOWED_ERR")
          ) if options.create and !writable
          return error(
            new PseudoFileError("PATH_EXISTS_ERR")
          ) if options.create and options.exclusive
          return success(entry)
      }
      return {
        fs: new Html5Fs(dummyDirEntry, @LOCAL)
        name: entry.name
      } # Last PromiseValue
    ) # return new Promise().then()

  ###*
  @static
  @method
    Choose directory from local
  @param {function(Error/null,AsyncFs):undefined} [callback]
    Callback function when Promise is not used
  @return {undefined/Promise}
    Promise object when callback is omitted
  @return {AsyncFs} return.PromiseValue
    New fs object for chosen directory
  ###
  @chooseDirectory: (callback) ->
    return invokeCallback(callback, @chooseDirectory()) if callback?
    return new Promise((resolve, reject) =>
      chrome.fileSystem.chooseEntry(
        {type: "openDirectory"}
        (entry) =>
          unless entry?
            error = chrome.runtime.lastError
            return reject(Error(error?.message or error))
          return resolve(new Html5Fs(entry, @LOCAL))
      )
    ) # return new Promise()

  #--------------------------------------------------------------------------------
  # Protected methods
  #

  ###*
  @protected
  @method constructor
    Constructor of AsyncFs class
  @param {string} _fsType
    Filesystem type identifier (AsyncFs.TEMPORARY etc.)
  ###
  constructor: (@_fsType) ->
    return

  ###*
  @protected
  @method
    Implement of getter for name property
  @return {string}
    The name of this directory
  ###
  getNameImpl: ->
    return

  ###*
  @protected
  @method
    Implement of mkdir method
  @param {string} path
    Directory path
  @param {number} mode
    Mode (permissions)
  @return {Promise}
    Promise object
  ###
  mkdirImpl: (path, mode) ->
    return Promise.reject(Error("Not supported"))

  ###*
  @protected
  @method
    Implement of readFile method
  @param {string} path
    File path
  @param {Object} options
    Options
  @return {Promise}
    Promise object
  @return {Object} return.PromiseValue
    Read data
  ###
  readFileImpl: (path, options) ->
    return Promise.reject(Error("Not supported"))

  ###*
  @protected
  @method
    Implement of rmdir method
  @param {string} path
    Directory path
  @return {Promise}
    Promise object
  ###
  rmdirImpl: (path) ->
    return Promise.reject(Error("Not supported"))

  ###*
  @protected
  @method
    Implement of writeFile method
  @param {string} path
    File path
  @param {Object} data
    Write data
  @param {Object} options
    Options
  @return {Promise}
    Promise object
  ###
  writeFileImpl: (path, data, options) ->
    return Promise.reject(Error("Not supported"))

  ###*
  @protected
  @method
    Implement of unlink method
  @param {string} path
    File path
  @return {Promise}
    Promise object
  ###
  unlinkImpl: (path) ->
    return Promise.reject(Error("Not supported"))

  ###*
  @protected
  @method
    Implement of opendirfs method
  @param {string} path
    File path
  @return {Promise}
    Promise object
  @return {AsyncFs} return.PromiseValue
    New fs object for directory
  ###
  opendirfsImpl: (path) ->
    return Promise.reject(Error("Not supported"))

  ###*
  @protected
  @method
    Implement of retainfs method
  @return {Promise}
    Promise object
  @return {Object} return.PromiseValue
    Object to describe retain information
  ###
  retainfsImpl: ->
    return Promise.reject(Error("Not supported"))

  ###*
  @protected
  @method
    Register retainable subclass
  @param {function} subclass
    Constructor of subclass
  @return {undefined}
  ###
  @retainable: (subclass) ->
    @_retainable.push(subclass)
    return

  #--------------------------------------------------------------------------------
  # Internal class
  #

  class PseudoFileError extends FileError
    constructor: (id) ->
      Object.defineProperty(this, "code", value: FileError[id])
      name = "_#{id}"
        .replace(/_ERR$/, "_ERROR").toLowerCase()
        .replace(/_([a-z])/g, (m, c) -> c.toUpperCase())
      Object.defineProperty(this, "name", value: name)
      Object.defineProperty(this, "message", value: "")
      if Error.captureStackTrace?
        Error.captureStackTrace(this, @constructor)
      else
        Error.call(this)
      return

# Post dependencies
I18n = require("util/i18n")
Html5Fs = require("filesystem/html5fs")
