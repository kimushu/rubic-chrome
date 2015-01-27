class FileUtil
  @readEntryText: (fileEntry, defaultText, successCallback, errorCallback) ->
    errorCallback or= -> successCallback(defaultText)
    fileEntry.file(
      ((file) ->
        reader = new FileReader
        reader.onload = -> successCallback(this.result)
        reader.onerror = errorCallback
        reader.readAsText(file)
      ),
      errorCallback
    )

  @readText: (dirEntry, path, defaultText, successCallback, errorCallback) ->
    errorCallback or= -> successCallback(defaultText)
    dirEntry.getFile(
      path,
      {create: false},
      ((fileEntry) ->
        FileUtil.readEntryText(fileEntry, null, successCallback, errorCallback)
      ),
      errorCallback
    )

  @writeText: (dirEntry, path, text, successCallback, errorCallback) ->
    errorCallback or= -> null
    dirEntry.getFile(
      path,
      {create: true},
      ((fileEntry) ->
        fileEntry.createWriter(
          ((writer) ->
            writer.onwrite = successCallback
            writer.onerror = errorCallback
            writer.write(new Blob([text]))
          ),
          errorCallback
        )
      ),
      errorCallback
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

