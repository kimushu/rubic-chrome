"use strict"
# Pre dependencies
TextEditor = require("editor/texteditor")
require("util/primitive")

###*
@class YamlEditor
  Editor for YAML text (View)
@extends TextEditor
###
module.exports = class YamlEditor extends TextEditor
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

  SUFFIX_RE = /\.ya?ml$/i

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
    Constructor of YamlEditor class
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

# Post dependencies
# (none)
