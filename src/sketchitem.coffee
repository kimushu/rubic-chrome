# Pre dependencies
JSONable = require("./jsonable")

###*
@class SketchItem
  Item in sketch (Model)
@extends JSONable
###
class SketchItem extends JSONable
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
  @property {boolean} modified
    Is this item modified
  @readonly
  ###
  @property("modified", get: -> @_modified)

  ###*
  @property {boolean} output
    The source of this item
  @readonly
  ###
  @property("output",
    get: -> @_output,
    set: (v) -> @_output = !!v; @_setModified()
  )

  ###*
  @property {boolean} transfer
    Is this item transfered to the board
  ###
  @property("transfer",
    get: -> @_transfer,
    set: (v) -> @_transfer = !!v; @_setModified()
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
    @_path = "#{obj.path}"
    @_modified = false
    @_output = !!obj.output
    @_transfer = !!obj.transfer
    @_editor = null
    return

  #--------------------------------------------------------------------------------
  # Protected methods
  #

  toJSON: ->
    return super().extends({
      path: @_path
      output: !!@_output
      transfer: !!@_transfer
    })

module.exports = SketchItem
