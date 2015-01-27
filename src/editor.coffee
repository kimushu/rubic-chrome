class Editor
  ##----------------------------------------------------------------
  ## Class attributes/methods
  ##----------------------------------------------------------------
  @_subclasses: []
  @_extendedBy: (subclass) -> @_subclasses.push(subclass)
  @_aceEditor: null
  $(->
    Editor._aceEditor = ace.edit("editor")
    ace.Document = ace.require("./document").Document
  )

  @open: (fileEntry) ->
    match = fileEntry.name.match(/\.(\w+$)/)
    ext = match[1].toLowerCase()
    for subc in @_subclasses
      return new subc(fileEntry) if subc.suffix.indexOf(ext) >= 0
    throw "Editor not found for *.#{ext} file"

  ##----------------------------------------------------------------
  ## Instance attributes/methods
  ##----------------------------------------------------------------
  @property('modified',
    get: -> @_modified
    set: (v) ->
      @_modified = v
      @onmodified(v) if @onmodified
  )

  onmodified: null

  _fileEntry: null

  constructor: (@_fileEntry, mode) ->
    @_session = new ace.createEditSession("", mode)

  ###*
  Activate editor
  ###
  activate: ->
    Editor._aceEditor.setSession(@_session)

  ###*
  Load text from file (Current contents of editor will be discarded)
  ###
  load: (successCallback, errorCallback) ->
    errorCallback or= -> null
    self = this
    @_fileEntry.file(
      ((file) ->
        reader = new FileReader
        reader.onload = ->
          self._session.getDocument().setValue(this.result)
          self.modified = false
          successCallback()
        reader.onerror = errorCallback
        reader.readAsText(file)
      ),
      errorCallback
    )

  ###*
  Save text to file
  ###
  save: (successCallback, errorCallback) ->
    self = this
    @_fileEntry.createWriter(
      ((writer) ->
        writer.onwrite = ->
          self.modified = false
          successCallback()
        writer.onerror = errorCallback
        writer.write(doc.getValue())
      ),
      errorCallback
    )

  close: ->

