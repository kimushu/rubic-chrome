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
    promise.then((value...) ->
      callback(null, value...)
      return
    ).catch((error) ->
      callback(error)
      return
    )
    return

  SEP         = "/"
  SEP_RE      = /\/+/
  SEP_LAST_RE = /\/+$/

  window.AsyncFs = AsyncFs  # For debugging

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
          return reject(Error(chrome.runtime.lastError)) unless entry?
          return resolve(entry)
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
    return I18n.getMessage("Not_supported")

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

# Post dependencies
I18n = require("util/i18n")
Html5Fs = require("filesystem/html5fs")
