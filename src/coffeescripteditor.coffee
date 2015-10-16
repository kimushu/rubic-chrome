###*
@class CoffeeScriptEditor
  Editor for CoffeeScript source (View)
@extends TextEditor
###
class CoffeeScriptEditor extends TextEditor
  DEBUG = if DEBUG? then DEBUG else 0
  Editor.addEditor(this)

  ###*
  @static
  @cfg {string[]}
    List of suffixes
  ###
  @SUFFIXES: ["coffee"]

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
    super(fileEntry, "ace/mode/coffee")
    return

  ###* @property _mode @hide ###
  ###* @property _aceSession @hide ###

