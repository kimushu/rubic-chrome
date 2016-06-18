# Pre dependencies
UnJSONable = require("./unjsonable")

###*
@class AsyncFs
  Asynchronous file system like fs module in Node.js
@extends Rubic.UnJSONable
###
class AsyncFs extends UnJSONable
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
    options = {encoding: options} if typeof(options) == "string"
    return @readFileImpl(file, options)

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
    options = {encoding: options} if typeof(options) == "string"
    return @writeFileImpl(file, data, options)

  ###*
  @method
    Unlink file
  @param {string} path
    File path
  @param {function(Error/null):undefined} [callback]
    Callback function when Promise is not used
  @return {undefined/Promise}
    Promise object when callback is omitted
  ###
  unlink: (path, callback) ->
    return invokeCallback(callback, @unlink(path)) if callback?
    return @unlinkImpl(path)

  #--------------------------------------------------------------------------------
  # Original methods
  #

  ###*
  @method
    Open directory as fs object
  @param {string} path
    File path
  @param {function(Error/null,Rubic.AsyncFs):undefined} [callback]
    Callback function when Promise is not used
  @return {undefined/Promise}
    Promise object when callback is omitted
  @return {Rubic.AsyncFs} return.PromiseValue
    New fs object for directory
  ###
  opendirfs: (path, callback) ->
    return invokeCallback(callback, @opendirfs(path)) if callback?
    return @opendirfsImpl(path)

  #--------------------------------------------------------------------------------
  # Protected methods
  #

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
  @param {string} file
    File path
  @param {Object} options
    Options
  @return {Promise}
    Promise object
  @return {Object} return.PromiseValue
    Read data
  ###
  readFileImpl: (file, options) ->
    return Promise.reject(Error("Not supported"))

  ###*
  @protected
  @method
    Implement of writeFile method
  @param {string} file
    File path
  @param {Object} data
    Write data
  @param {Object} options
    Options
  @return {Promise}
    Promise object
  ###
  writeFileImpl: (file, data, options) ->
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
  @return {Rubic.AsyncFs} return.PromiseValue
    New fs object for directory
  ###
  opendirfsImpl: (path) ->
    return Promise.reject(Error("Not supported"))

module.exports = AsyncFs
