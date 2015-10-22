###*
@class JavaScriptEditor
  Editor for JavaScript source (View)
@extends TextEditor
###
class JavaScriptEditor extends TextEditor
  DEBUG = if DEBUG? then DEBUG else 0
  Editor.addEditor(this)

  ###*
  @static
  @cfg {string[]}
    List of suffixes
  ###
  @SUFFIXES: ["js"]

  ###*
  @static
  @cfg {boolean}
    Editable or not
  @readonly
  ###
  @EDITABLE: true

  ###*
  @method constructor
    Constructor
  @param {FileEntry} fileEntry
    FileEntry for this document
  ###
  constructor: (fileEntry) ->
    super(fileEntry, "ace/mode/javascript")
    return

  ###* @property _mode @hide ###
  ###* @property _aceSession @hide ###

