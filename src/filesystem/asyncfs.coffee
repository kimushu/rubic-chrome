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
  # Original properties
  #

  ###*
  @property {string} name
    The name of directory
  @readonly
  ###
  @property("name", get: -> @getNameImpl())

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
        (fs) => resolve(new Html5Fs(fs.root))
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
        fs: new Html5Fs(dummyDirEntry)
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
          return resolve(new Html5Fs(entry))
      )
    ) # return new Promise()

  #--------------------------------------------------------------------------------
  # Protected methods
  #

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
    return I18n.rejectPromise("Not_supported")

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
    return I18n.rejectPromise("Not_supported")

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
    return I18n.rejectPromise("Not_supported")

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
    return I18n.rejectPromise("Not_supported")

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
    return I18n.rejectPromise("Not_supported")

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
    return I18n.rejectPromise("Not_supported")

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
