###*
@class Rubic.RubyEditor
  Editor for ruby/mruby source (View)
@extends Rubic.TextEditor
###
class Rubic.RubyEditor extends Rubic.TextEditor
  DEBUG = Rubic.DEBUG or 0
  Rubic.Editor.addEditor(this)

  ###*
  @static
  @cfg {string[]}
    List of suffixes
  ###
  @SUFFIXES: ["rb"]

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
    super(controller, fileEntry, "ace/mode/ruby")
    return

