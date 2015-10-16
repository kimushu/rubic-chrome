###*
@class TextEditor
  Base class for text editors (View)
@extends Editor
###
class TextEditor extends Editor
  DEBUG = if DEBUG? then DEBUG else 0

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
  @property {string}
    Mode string for Ace
  @readonly
  ###
  _mode: null

  ###*
  @private
  @property {ace.EditSession}
    Ace edit session instance
  @readonly
  ###
  _aceSession: null

  ###*
  @protected
  @method constructor
    Constructor
  @param {FileEntry} fileEntry
    FileEntry for this document
  @param {string} _mode
    Mode string for Ace
  ###
  constructor: (fileEntry, @_mode) ->
    super(fileEntry, $("#editor")[0])
    @constructor.ace or= ace.edit(@element)
    @_aceSession = new ace.createEditSession("", @_mode)
    @_aceSession.on("change", =>
      @modified = true
      @fireChange()
    )
    return

  ###*
  @inheritdoc Editor#load
  ###
  load: (callback) ->
    FileUtil.readArrayBuf(@fileEntry, (res_read, buffer) =>
      return callback(false) unless res_read
      @convertForReading(buffer, (res_conv, text) =>
        return callback(false) unless res_conv
        @_aceSession.setValue(text)
        return callback(true)
      )
    )
    return

  ###*
  @inheritdoc Editor#save
  ###
  save: (callback) ->
    @convertForWriting(@aceSession.getValue(), (res_conv, buffer) =>
      return callback(false) unless res_conv
      FileUtil.writeArrayBuf(@fileEntry, buffer, (res_write) =>
        return callback(false) unless res_write
        @modified = false
        @fireChange()
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

  ###* @property _editorId @hide ###
  ###* @property _name @hide ###
  ###* @method _updateTab @hide ###

