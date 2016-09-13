"use strict"
# Pre dependencies
TextEditor = require("editor/texteditor")
require("util/primitive")

###*
@class PlainTextViewer
  Editor for plain text (View)
@extends TextEditor
###
module.exports = class PlainTextEditor extends TextEditor
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
  # Private variables / constants
  #

  SUFFIX_RE = /\.(txt|log|dump)$/i

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
    Constructor of PlainTextEditor class
  @param {jQuery} $
    jQuery object
  @param {Sketch} sketch
    Sketch
  @param {SketchItem} sketchItem
    Sketch item
  ###
  constructor: ($, sketch, sketchItem) ->
    super($, sketch, sketchItem, "ace/mode/text")
    return

# Post dependencies
# (none)
