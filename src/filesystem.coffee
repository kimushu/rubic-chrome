class FileSystem
  ###*
  Request filesystem access
  @param {String}   name      Name(classname) of filesystem to request
  @param {Function} callback  Callback (Object filesystem)
  ###
  @request: (name, callback) ->
    @_fileSystems[id].request(callback)

  ###*
  Display choose entry dialog and get an entry
  @param {String}   options.type  Type of the prompt to show
                                  ("openWritableFile", "openDirectory")
  @param {Function} callback      Callback (Object entry)
  ###
  chooseEntry: (options, callback) ->
    throw "Not implemented" #unless @asyncFS
    # reader = @asyncFS.root.createReader()
    # entries = []
    # reader.readEntries((e) =>
    #   return entries = entries.concat(e) if e.length > 0
    #   entries
    # )

  ###*
  @protected
  Register filesystem class
  ###
  @addFileSystem: (subclass) -> @_fileSystems[subclass.name] = subclass

  ###*
  @protected
  W3C asynchronous filesystem interface (if available)
  ###
  @asyncFS: null

  ###*
  @private
  List of filesystem classes
  ###
  @_fileSystems: {}


