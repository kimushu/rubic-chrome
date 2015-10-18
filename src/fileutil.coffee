###*
@class Rubic.FileUtil
  Class for file access utilities
###
class Rubic.FileUtil
  DEBUG = Rubic.DEBUG or 0

  ###*
  @static
  @method
    Read text from FileEntry or pair of DirectoryEntry and path
  @param {Object}   entry       FileEntry or [DirectoryEntry, path] to read
  @param {Function} callback    Callback ({Boolean} result, {String} readdata)
  @param {Object}   [options]   Options for DirectoryEntry#getFile
  @return {void}
  ###
  @readText: (entry, callback, options) ->
    @_read(
      entry
      callback
      (reader, file) -> reader.readAsText(file)
      options
    )
    return

  ###*
  @static
  @method
    Read JSON from FileEntry or pair of DirectoryEntry and path
  @param {Object}   entry       FileEntry or [DirectoryEntry, path] to read
  @param {Function} callback    Callback ({Boolean} result, {Object} readdata)
  @param {Object}   [options]   Options for DirectoryEntry#getFile
  @return {void}
  ###
  @readJSON: (entry, callback, options) ->
    @readText(
      entry
      (result, readdata) ->
        return callback?(false, null) unless result
        obj = {}
        try
          obj = JSON.parse(readdata) unless readdata == ""
        catch error
          obj = null
        return callback?((obj != null), obj)
      options
    )
    return

  ###*
  @static
  @method
    Read data as ArrayBuffer from FileEntry or pair of DirectoryEntry and path
  @param {Object}   entry       FileEntry or [DirectoryEntry, path] to read
  @param {Function} callback    Callback ({Boolean} result, {ArrayBuffer} readdata)
  @param {Object}   [options]   Options for DirectoryEntry#getFile
  @return {void}
  ###
  @readArrayBuf: (entry, callback, options) ->
    @_read(
      entry
      callback
      (reader, file) -> reader.readAsArrayBuffer(file)
      options
    )
    return

  ###*
  @private
  @static
  @method
    Read data from FileEntry or pair of DirectoryEntry and path
  @param {Object}   entry       FileEntry of [DirectoryEntry, path] to read
  @param {Function} callback    Callback ({Boolean} result, {ArrayBuffer} readdata)
  @param {Function} invoke      Reader function ({FileReader} reader, {File} file)
  @param {Object}   [options]   Options for DirectoryEntry#getFile
  @return {void}
  ###
  @_read: (entry, callback, invoke, options) ->
    options or= {}
    options.create or= false
    if entry instanceof Array
      [dirEntry, path] = entry
      dirEntry.getFile(
        path
        options
        (fileEntry) => @_read(fileEntry, callback, invoke)
        -> callback?(false)
      ) # dirEntry.getFile
    else
      entry.file(
        (file) ->
          reader = new FileReader
          reader.onload = -> callback?(true, this.result)
          reader.onerror = -> callback?(false)
          invoke(reader, file)
        -> callback?(false)
      ) # entry.file
    return

  ###*
  @static
  @method
    Write text to FileEntry or pair of DirectoryEntry and path
  @param {Object} entry
    FileEntry or [DirectoryEntry, path] to write
  @param {string} text
    Data to write
  @param {function(boolean):void} callback
    Callback function with result
  @return {void}
  ###
  @writeText: (entry, text, callback) ->
    @_write(entry, text, callback)
    return

  ###*
  @static
  @method
    Write object as JSON to FileEntry or pair of DirectoryEntry and path
  @return {void}
  ###
  @writeJSON: (entry, data, callback) ->
    @writeText(entry, JSON.stringify(data), callback)
    return

  ###*
  @static
  @method
    Write ArrayBuffer to FileEntry or pair of DirectoryEntry and path
    (Alias of FileUtil.write)
  ###
  @writeArrayBuf: -> @_write.apply(this, arguments)

  ###*
  @private
  @static
  @method
    Write data to FileEntry or pair of DirectoryEntry and path
  @param {Object}                         entry     FileEntry or [DirectoryEntry, path] to write
  @param {String/ArrayBuffer/TypedArray}  data      Data to write
  @param {Function}                       callback  Callback ({Boolean} result)
  ###
  @_write: (entry, data, callback) ->
    if entry instanceof Array
      [dirEntry, path] = entry
      dirEntry.getFile(
        path
        {create: true}
        (fileEntry) => @_write(fileEntry, data, callback)
        -> callback?(false)
      ) # dirEntry.getFile
    else
      entry.createWriter(
        (writer) ->
          truncated = false
          writer.onwriteend = ->
            return callback?(true) if truncated
            truncated = true
            this.write(new Blob([data]))
          writer.onerror = -> callback?(false)
          writer.truncate(0)
        -> callback?(false)
      ) # entry.createWriter

  ###*
  @static
  @method
    Wrapper function for fs.readEntries to get all entries at once
  @param {DirectoryEntry} dirEntry          Directory to read entries
  @param {Function}       successCallback   Callback ({FileEntry[]} entries)
  @param {Function}       [errorCallback]   Error callback ({void})
  ###
  @readEntries: (dirEntry, successCallback, errorCallback) ->
    result = []
    reader = dirEntry.createReader()
    readEntries = null
    readEntries = ->
      reader.readEntries(
        (entries) ->
          if(entries.length == 0)
            successCallback?(result)
          else
            result = result.concat(entries)
            readEntries()
        errorCallback or (-> undefined)
      )
    readEntries()
    undefined

  ###*
  @static
  @method
    Wrapper function for PERSISTENT filesystem
  @param {Function} successCallback   Callback ({FileSystem} fs)
  @param {Function} [errorCallback]   Error callback ({void})
  ###
  @requestPersistentFileSystem: (successCallback, errorCallback) ->
    errorCallback or= (-> undefined)
    navigator.webkitPersistentStorage.queryUsageAndQuota(
      (used, granted) ->
        window.webkitRequestFileSystem(
          PERSISTENT,
          granted,
          successCallback,
          errorCallback
        ) # webkitRequestFileSystem
      errorCallback
    )
    undefined

  ###*
  @static
  @method
    Wrapper function for TEMPORARY filesystem
  @param {Function} successCallback   Callback ({FileSystem} fs)
  @param {Function} [errorCallback]   Error callback ({void})
  ###
  @requestTemporaryFileSystem: (successCallback, errorCallback) ->
    errorCallback or= (-> undefined)
    navigator.webkitTemporaryStorage.queryUsageAndQuota(
      (used, granted) ->
        window.webkitRequestFileSystem(
          TEMPORARY,
          granted,
          successCallback,
          errorCallback
        ) # webkitRequestFileSystem
      errorCallback
    )
    undefined

