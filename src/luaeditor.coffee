"use strict"
# Pre dependencies
TextEditor = require("./texteditor")
require("./primitive")

###*
@class LuaEditor
  Editor for Lua script source (View)
@extends TextEditor
###
module.exports = class LuaEditor extends TextEditor
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

  SUFFIX_RE = /\.lua$/i

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
    Constructor of LuaEditor class
  @param {jQuery} $
    jQuery object
  @param {Sketch} sketch
    Sketch instance
  @param {string} path
    Path of target file
  ###
  constructor: ($, sketch, path) ->
    super($, sketch, path, "ace/mode/lua")
    return

# Post dependencies
# (none)
