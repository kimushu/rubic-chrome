class LocalFileSystem extends FileSystem
  @location: "Local file system"
  FileSystem.addFileSystem(this)

  ###*
  Request local storage file system
  ###
  @request: (callback) ->
    callback(new @constructor)

