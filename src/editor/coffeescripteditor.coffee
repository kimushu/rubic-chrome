"use strict"
# Pre dependencies
TextEditor = require("editor/texteditor")
require("util/primitive")

###*
@class CoffeeScriptEditor
  Editor for CoffeeScript source (View)
@extends TextEditor
###
module.exports = class CoffeeScriptEditor extends TextEditor
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

  SUFFIX_RE = /\.coffee$/i

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
    Constructor of CoffeeScriptEditor class
  @param {jQuery} $
    jQuery object
  @param {Sketch} sketch
    Sketch instance
  @param {string} path
    Path of target file
  ###
  constructor: ($, sketch, path) ->
    super($, sketch, path, "ace/mode/coffee")
    return

# Post dependencies
# (none)
