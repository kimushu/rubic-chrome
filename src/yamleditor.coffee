# Dependencies
TextEditor = require("./texteditor")

###*
@class YAMLEditor
  Editor for YAML text (View)
@extends TextEditor
###
class YAMLEditor extends TextEditor
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

  SUFFIX_RE = /\.ya?ml$/i

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
    Constructor of RubyEditor class
  @param {jQuery} $
    jQuery object
  @param {Sketch} sketch
    Sketch instance
  @param {string} path
    Path of target file
  ###
  constructor: ($, sketch, path) ->
    super($, sketch, path, "ace/mode/yaml")
    return

module.exports = YAMLEditor
