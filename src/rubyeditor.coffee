# Pre dependencies
TextEditor = require("./texteditor")

###*
@class RubyEditor
  Editor for ruby/mruby source (View)
@extends TextEditor
###
class RubyEditor extends TextEditor
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
  # Private variables
  #

  SUFFIX_RE = /\.rb$/i

  #--------------------------------------------------------------------------------
  # Public properties
  #

  ###*
  @inheritdoc Editor#supports
  ###
  @supports: (item) ->
    return !!item.path.match(SUFFIX_RE)

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
  @param {SketchItem} item
    Sketch item
  ###
  constructor: ($, sketch, item) ->
    super($, sketch, item, "ace/mode/ruby")
    return

module.exports = RubyEditor

# Post dependencies
# (none)
