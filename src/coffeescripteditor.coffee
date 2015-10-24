###*
@class CoffeeScriptEditor
  Editor for CoffeeScript source (View)
@extends TextEditor
###
class Rubic.CoffeeScriptEditor extends Rubic.TextEditor
  DEBUG = if DEBUG? then DEBUG else 0
  Rubic.Editor.addEditor(this)

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
  @static
  @method
    Get new file template
  @param {Object} header
    Header information
  @return {string}
    Template text
  ###
  @getTemplate: (header) ->
    return """
    # #{Rubic.I18n("WriteYourSketchHere")}

    """

  ###*
  @method constructor
    Constructor
  @param {Rubic.WindowController} controller
    Controller for this view
  @param {FileEntry} fileEntry
    FileEntry for this document
  ###
  constructor: (controller, fileEntry) ->
    super(controller, fileEntry, "ace/mode/coffee")
    return

  ###* @property _mode @hide ###
  ###* @property _aceSession @hide ###

