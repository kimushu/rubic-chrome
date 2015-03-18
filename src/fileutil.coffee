class FileUtil
  ###*
  Read text to FileEntry or pair of DirectoryEntry and path
  @param {Object}   entry       FileEntry or [DirectoryEntry, path] to read
  @param {Function} callback    Callback ({Boolean} result, {String} readdata)
  ###
  @readText: (entry, callback) ->
    if entry instanceof Array
      [dirEntry, path] = entry
      dirEntry.getFile(
        path,
        {create: false},
        ((fileEntry) -> FileUtil.readText(fileEntry, callback)),
        (-> callback(false))
      )
    else
      entry.file(
        ((file) ->
          reader = new FileReader
          reader.onload = -> callback(true, @result)
          reader.onerror = -> callback(false)
          reader.readAsText(file)
        ),
        (-> callback(false))
      )

  ###*
  Write text to FileEntry or pair of DirectoryEntry and path
  @param {Object}   entry       FileEntry or [DirectoryEntry, path] to write
  @param {String}   text        Text to write
  @param {Function} callback    Callback ({Boolean} result)
  ###
  @writeText: (entry, text, callback) ->
    if entry instanceof Array
      [dirEntry, path] = entry
      dirEntry.getFile(
        path,
        {create: true},
        ((fileEntry) -> FileUtil.writeText(fileEntry, text, callback)),
        (-> callback(false))
      )
    else
      entry.createWriter(
        ((writer) ->
          truncated = false
          writer.onwriteend = ->
            return callback(true) if truncated
            truncated = true
            @write(new Blob([text]))
          writer.onerror = -> callback(false)
          writer.truncate(0)
        ),
        (-> callback(false))
      )

  @readEntries: (dirEntry, successCallback, errorCallback) ->
    errorCallback or= -> null
    result = []
    reader = dirEntry.createReader()
    readEntries = null
    readEntries = ->
      reader.readEntries(
        ((entries) ->
          if(entries.length == 0)
            successCallback(result)
          else
            result = result.concat(entries)
            readEntries()
        ),
        errorCallback
      )
    readEntries()

