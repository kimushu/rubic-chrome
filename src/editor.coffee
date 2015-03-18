###*
@class
Base class for editors
###
class Editor
  #----------------------------------------------------------------
  # Private constants

  #----------------------------------------------------------------
  # Class attributes/methods

  ###*
  Open new editor
  @param {FileEntry}      fileEntry   File to open
  ###
  @open: (fileEntry) ->
    match = fileEntry.name.match(/\.(\w+$)/)
    ext = match[1].toLowerCase()
    for editor in @_editors
      return new editor(fileEntry) if editor.suffix.indexOf(ext) >= 0
    throw new Error("Editor not found for *.#{ext} file")

  ###*
  @protected
  Register editor/viewer class
  @param {Function}       editor      Class constructor
  ###
  @addEditor: (editor) -> @_editors.push(editor)

  ###*
  @private
  List of editor/viewer classes
  ###
  @_editors: []

  ###*
  @private
  Next ID number for editors
  ###
  @_nextId: 0

  ###*
  @private
  Instance of ace.Editor
  ###
  @_aceEditor: null
  $(=>
    @_aceEditor = ace.edit("editor")
    ace.Document = ace.require("./document").Document
    @_aceEditor.on("changeSession", ({oldSession, session}) ->
      oldSession._editor?.onDeactivated()
      session._editor?.onActivated()
    )
    @_aceEditor.on("change", =>
      App.sketch?.markModified()
      @_aceEditor.getSession()?._editor?.markModified()
    )
  )

  #----------------------------------------------------------------
  # Instance attributes/methods

  ###*
  @protected
  Constructor
  @param {FileEntry}      fileEntry   File to be associated with this editor
  @param {String}         mode        Mode string for ace
  ###
  constructor: (@fileEntry, mode) ->
    @_domId = "editor-#{@constructor._nextId}"
    @constructor._nextId += 1
    @_session = new ace.createEditSession("", mode)
    @_session._editor = this
    li = $("<li id=\"#{@_domId}\">#{@fileEntry.name}"+
      "<span class=\"modified\" style=\"display:none\"> *</span></li>")
    li.click(=> @activate())
    $("#file-tabbar").append(li)

  ###*
  Load text from file (Current contents of editor will be discarded)
  @param {Function}       callback    Callback ({Boolean} result)
  ###
  load: (callback) ->
    FileUtil.readText(@fileEntry, (result, readdata) =>
      unless result
        Notify.error("Failed to read #{@fileEntry.name}")
        return callback(false)
      @_session.getDocument().setValue(readdata)
      @modified = false
      callback(true)
    )

  ###*
  Save text to file
  @param {Function}       callback    Callback ({Boolean} result)
  ###
  save: (callback) ->
    @saveAs(null, callback)

  ###*
  Save text to new file
  @param {DirectoryEntry} dirEntry    Directory to save @nullable
  @param {Function}       callback    Callback ({Boolean} result)
  ###
  saveAs: (dirEntry, callback) ->
    name = @fileEntry.name
    dest = if dirEntry then [dirEntry, name] else @fileEntry
    doc = @_session.getDocument()
    FileUtil.writeText(dest, doc.getValue(), (result) =>
      unless result
        Notify.error("Failed to write #{name}")
        return callback(false)
      @markModified(false)
      return callback(true) unless dirEntry
      dirEntry.getFile(
        name
        {}
        (@fileEntry) => callback(true)
        ->
          Notify.error("Failed to reopen #{name}")
          callback(false)
      ) # dirEntry.getFile
    )

  close: ->

  ###*
  Activate editor
  ###
  activate: ->
    Editor._aceEditor.setSession(@_session)

  ###*
  @private
  Event on activated
  ###
  onActivated: ->
    $("li##{@_domId}").addClass("active")

  ###*
  @private
  Event on deactivated
  ###
  onDeactivated: ->
    $("li##{@_domId}").toggleClass("active", false)

  ###*
  @property {Boolean}
  Is document modified after latest save?
  ###
  modified: false

  ###*
  Set mark as modified
  ###
  markModified: (value = true) ->
    return if @modified == value
    $("li##{@_domId}").children(".modified").css({display: if value then "inline" else "none"})
    @modified = value

  ###*
  @protected
  @property {FileEntry}
  Is document modified after latest save?
  ###
  fileEntry: null

  ###*
  @private
  @property {ace.EditSession}
  Ace session
  ###
  _session: null

  ###*
  @private
  @property {String}
  DOM element id for this editor
  ###
  _domId: null

