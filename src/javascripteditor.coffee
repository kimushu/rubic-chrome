# Dependencies
TextEditor = require("./texteditor")

###*
@class JavaScriptEditor
  Editor for JavaScript source (View)
@extends TextEditor
###
class JavaScriptEditor extends TextEditor
  TextEditor.register(this)

  #--------------------------------------------------------------------------------
  # Public properties
  #

  ###*
  @static
  @inheritdoc Editor#editable
  @readonly
  ###
  @editable: true

  #--------------------------------------------------------------------------------
  # Private constants
  #

  SUFFIX_RE = /\.js$/i

  #--------------------------------------------------------------------------------
  # Public properties
  #

  ###*
  @inheritdoc Editor#supports
  ###
  @supports: (path) ->
    return !!path.match(SUFFIX_RE)

  #--------------------------------------------------------------------------------
  # Protected properties
  #

  ###*
  @protected
  @method constructor
    Constructor of JavaScriptEditor class
  @param {jQuery} $
    jQuery object
  @param {Sketch} sketch
    Sketch instance
  @param {string} path
    Path of target file
  ###
  constructor: ($, sketch, path) ->
    super($, sketch, path, "ace/mode/javascript")
    return

module.exports = JavaScriptEditor
