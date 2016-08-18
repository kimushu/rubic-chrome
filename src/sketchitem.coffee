"use strict"
# Pre dependencies
JSONable = require("./jsonable")
require("./primitive")

###*
@class SketchItem
  Item in sketch (Model)
@extends JSONable
###
module.exports = class SketchItem extends JSONable
  SketchItem.jsonable()

  #--------------------------------------------------------------------------------
  # Public properties
  #

  ###*
  @property {Sketch} sketch
    The sketch which owns this items
  @readonly
  ###
  @property("sketch", get: -> @_sketch)

  ###*
  @property {string} path
    Path of this item
  @readonly
  ###
  @property("path", get: -> @_path)

  ###*
  @property {string} name
    Name of this item
  @readonly
  ###
  @property("name", get: -> return @_path.split("/").pop())

  ###*
  @property {string[]} generatedFrom
    The list of sources of this item
  @readonly
  ###
  @property("generatedFrom", get: -> (v for v in @_generatedFrom))

  ###*
  @property {boolean} transfer
    Is this item transfered to the board
  ###
  @property("transfer",
    get: -> @_transfer,
    set: (v) -> @_transfer = !!v; @_setModified()
  )

  ###*
  @property {boolean} hasCompilerOptions
    Enable compiler options for this file
  ###
  @property("hasCompilerOptions",
    get: -> @_hasCompilerOptions
    set: (v) -> @_hasCompilerOptions = !!v; @_setModified()
  )

  ###*
  @property {string} compilerOptions
    The options for compiler
  ###
  @property("compilerOptions",
    get: -> @_compilerOptions
    set: (v) -> @_compilerOptions = "#{v || ""}"; @_setModified()
  )

  ###*
  @property {Editor} editor
    The editor for this item
  ###
  @property("editor",
    get: -> @_editor,
    set: (v) -> @_editor = v
  )

  #--------------------------------------------------------------------------------
  # Public methods
  #

  ###*
  @method constructor
    Constructor of SketchItem class
  @param {Object} obj
    JSON object
  @param {Sketch} _sketch
    Owner sketch
  ###
  constructor: (obj, @_sketch) ->
    @_path = "#{obj?.path}"
    @_generatedFrom = obj?.generatedFrom?.map?((v) -> "#{v}") || []
    @_transfer = !!obj?.transfer
    @_hasCompilerOptions = !!obj?.hasCompilerOptions
    @_compilerOptions = "#{obj?.compilerOptions || ""}"
    @_editor = null
    return

  ###*
  @method
    Update sketch relationship
  @param {Sketch} _sketch
    Owner sketch
  @return {undefined}
  ###
  setSketch: (@_sketch) ->
    return

  #--------------------------------------------------------------------------------
  # Protected methods
  #

  ###*
  @protected
  @inheritdoc JSONable#toJSON
  ###
  toJSON: ->
    return super().extends({
      path: @_path
      generatedFrom: @_generatedFrom
      transfer: @_transfer
      hasCompilerOptions: @_hasCompilerOptions
      compilerOptions: @_compilerOptions
    })

  #--------------------------------------------------------------------------------
  # Private methods
  #

  ###*
  @private
  @method
    Set modified flag
  @return {undefined}
  ###
  _setModified: ->
    @_sketch?.modified = true
    return

# Post dependencies
# (none)
