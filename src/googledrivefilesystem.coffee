class GoogleDriveFileSystem extends FileSystem
  @location: "Google Drive"
  FileSystem.addFileSystem(this)

  ###*
  Request Google Drive file system
  ###
  @request: (callback) ->
    chrome.syncFileSystem.requestFileSystem((syncFS) ->
      callback(new @constructor(syncFS))
    )

  ###*
  @private
  Constructor
  ###
  constructor: (@syncFS) ->

  ###*
  Display choose entry dialog and get an entry
  @param {String}   options.type  Type of the prompt to show
                                  ("openWritableFile", "openDirectory")
  @param {Function} callback      Callback (Object entry)
  ###
  chooseEntry: (options, callback) ->

