class FileUtil
  ###*
  Read text from FileEntry or pair of DirectoryEntry and path
  @param {Object}   entry       FileEntry or [DirectoryEntry, path] to read
  @param {Function} callback    Callback ({Boolean} result, {String} readdata)
  ###
  @readText: (entry, callback) ->
    @_read(entry, callback, (reader, file) -> reader.readAsText(file))

  ###*
  Read data as ArrayBuffer from FileEntry or pair of DirectoryEntry and path
  @param {Object}   entry       FileEntry or [DirectoryEntry, path] to read
  @param {Function} callback    Callback ({Boolean} result, {ArrayBuffer} readdata)
  ###
  @readArrayBuf: (entry, callback) ->
    @_read(entry, callback, (reader, file) -> reader.readAsArrayBuffer(file))

  ###*
  @private
  Read data from FileEntry or pair of DirectoryEntry and path
  ###
  @_read: (entry, callback, invoke) ->
    if entry instanceof Array
      [dirEntry, path] = entry
      dirEntry.getFile(
        path
        {create: false}
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

  ###*
  Write text to FileEntry or pair of DirectoryEntry and path
  (Alias of FileUtil.write)
  ###
  @writeText: -> @_write.apply(this, arguments)

  ###*
  Write ArrayBuffer to FileEntry or pair of DirectoryEntry and path
  (Alias of FileUtil.write)
  ###
  @writeArrayBuf: -> @_write.apply(this, arguments)

  ###*
  @private
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

  @readEntries: (dirEntry, successCallback, errorCallback) ->
    errorCallback or= -> null
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
        errorCallback
      )
    readEntries()

