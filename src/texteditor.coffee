###*
@class Rubic.TextEditor
  Base class for text editors (View)
@extends Rubic.Editor
###
class Rubic.TextEditor extends Rubic.Editor
  DEBUG = Rubic.DEBUG or 0

  ###*
  @protected
  @static
  @property {ace.Editor}
    Ace editor instance
  @readonly
  ###
  @ace: null

  ###*
  @private
  @static
  @property {ace.EditSession}
    An empty EditSession
  @readonly
  ###
  @_aceEmptySession: null

  ###*
  @protected
  @property {ace.Editor}
    Reference of Ace editor instance
  @readonly
  ###
  @property("ace", get: -> Rubic.TextEditor.ace)

  ###*
  @protected
  @method constructor
    Constructor
  @param {Rubic.WindowController} controller
    Controller for this view
  @param {FileEntry} fileEntry
    FileEntry for this document
  @param {string} _mode
    Mode string for Ace
  ###
  constructor: (controller, fileEntry, @_mode) ->
    super(controller, fileEntry, controller.$("#text-editor")[0])
    Rubic.TextEditor.ace or= controller.window.ace.edit(@element)
    Rubic.TextEditor._aceEmptySession or= Rubic.TextEditor.ace.getSession()
    @_ignoreChange = false
    @_aceSession = new controller.window.ace.createEditSession("", @_mode)
    @_aceSession.on("change", =>
      return unless @_aceSession
      return if @_ignoreChange
      @modified = true
    )
    return

  ###*
  @inheritdoc Rubic.Editor#load
  ###
  load: (callback) ->
    Rubic.FileUtil.readArrayBuf(@fileEntry, (res_read, buffer) =>
      return callback(false) unless res_read
      @convertForReading(buffer, (res_conv, text) =>
        return callback(false) unless res_conv
        @_ignoreChange = true
        @_aceSession.setValue(text)
        @_ignoreChange = false
        return callback(true)
      )
    )
    return

  ###*
  @inheritdoc Rubic.Editor#save
  ###
  save: (callback) ->
    @convertForWriting(@_aceSession.getValue(), (res_conv, buffer) =>
      return callback(false) unless res_conv
      Rubic.FileUtil.writeArrayBuf(@fileEntry, buffer, (res_write) =>
        return callback(false) unless res_write
        @modified = false
        return callback(true)
      )
    )
    return

  ###*
  @protected
  @method
    Convert for reading (default: convert to UTF-8 text)
  @param {ArrayBuffer}  rawdata
    ArrayBuffer of raw data
  @param {function(boolean,string)} callback
    Callback function with result and converted data
  @return {void}
  ###
  convertForReading: (rawdata, callback) ->
    reader = new FileReader()
    reader.onloadend = -> return callback(true, reader.result)
    reader.onerror = -> return callback(false, null)
    reader.readAsText(new Blob([rawdata]))
    return

  ###*
  @protected
  @method
    Convert for writing (default: convert from UTF-8 text)
  @param {string} text
    Text data
  @param {function(boolean,ArrayBuffer)}  callback
    Callback function with result and converted data
  @return {void}
  ###
  convertForWriting: (text, callback) ->
    reader = new FileReader()
    reader.onloadend = -> return callback(true, reader.result)
    reader.onerror = -> return callback(false, null)
    reader.readAsArrayBuffer(new Blob([text]))
    return

  ###*
  @inheritdoc Rubic.Editor#activate
  ###
  activate: (callback) ->
    @ace.setSession(@_aceSession)
    super(callback)
    @ace.focus()
    return

  ###*
  @inheritdoc Rubic.Editor#close
  ###
  close: (callback) ->
    super((result) =>
      if result
        if @ace.getSession() == @_aceSession
          @ace.setSession(Rubic.TextEditor._aceEmptySession)
        @_aceSession = null
      callback(result)
    )
    return

  ###* @property _editorId @hide ###
  ###* @property _name @hide ###
  ###* @method _updateTab @hide ###

