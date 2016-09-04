"use strict"
# Pre dependencies
JSONable = require("util/jsonable")
require("util/primitive")

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
    set: (v) -> @_modify("_transfer", !!v)
  )

  ###*
  @property {string} compilerOptions
    The options for compiler
  ###
  @property("compilerOptions",
    get: -> @_compilerOptions
    set: (v) -> @_modify("_compilerOptions", v?.toString() or "")
  )

  ###*
  @property {Engine} engine
    The engine instance associated to this file
  ###
  @property("engine",
    get: -> @_engine
    set: (v) -> @_engine = v
  )

  ###*
  @property {Editor} editor
    The editor for this item
  ###
  @property("editor",
    get: -> @_editor,
    set: (v) -> @_editor = v
  )

  ###*
  @property {boolean} alreadyTransfered
    Flag for skip of transfer
  ###
  @property("alreadyTransfered",
    get: -> @_alreadyTransfered
    set: (v) -> @_alreadyTransfered = !!v
  )

  #--------------------------------------------------------------------------------
  # Events
  #

  ###*
  @event change
    SketchItem changed (excludes content's change)
  @param {Object} event
    Event object
  @param {SketchItem} event.target
    SketchItem instance
  ###
  @event("change")

  ###*
  @event contentchange
    Content of SketchItem changed
  @param {Object} event
    Event object
  @param {SketchItem} event.target
    SketchItem instance
  ###
  @event("contentchange")

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
  constructor: (obj = {}, @_sketch) ->
    @_path = "#{obj.path}"
    @_generatedFrom = obj.generatedFrom?.map?((v) -> "#{v}") or []
    @_transfer = !!obj.transfer
    @_compilerOptions = obj.compilerOptions?.toString()
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

  ###*
  @method
    Add generator relationship
  @param {SketchItem} item
    SketchItem instance which generates this item
  @return {undefined}
  ###
  addGenerator: (item) ->
    path = item.path
    unless @_generatedFrom.includes(path)
      @_generatedFrom.push(path)
      @dispatchEvent({type: "change"})
    return

  ###*
  @method
    Read content
  @param {Object/null} [options]
    Options passed to AsyncFs#readFile
  @return {Promise}
    Promise object
  @return {ArrayBuffer} return.PromiseValue
    Data
  ###
  readContent: (options) ->
    return Promise.reject(Error("No sketch")) unless @_sketch?
    return @_sketch.dirFs.readFile(@_path, options)

  ###*
  @method
    Write content
  @param {ArrayBuffer} content
    Content to write
  @param {Object/null} [options]
    Options passed to AsyncFs#writeFile
  @return {Promise}
    Promise object
  ###
  writeContent: (content, options) ->
    return Promise.reject(Error("No sketch")) unless @_sketch?
    return @_sketch.dirFs.writeFile(@_path, content, options).then(=>
      @dispatchEvent({type: "contentchange"})
      return
    )

  ###*
  @method
    Rename item
  @param {string} newPath
    New path
  @return {Promise}
    Promise object
  ###
  rename: (newPath) ->
    return Promise.reject(Error("No sketch")) unless @_sketch?
    return Promise.resolve() if newPath == @_path
    oldPath = @_path
    return Promise.resolve(
    ).then(=>
      return @readContent()
    ).then((content) =>
      @_path = newPath
      return @writeContent(content)
    ).then(=>
      return @_sketch.dirFs.unlink(oldPath)
    ).catch((error) =>
      @_path = oldPath
      return Promise.reject(error)
    ) # return Promise.resolve().then()...

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
      compilerOptions: @_compilerOptions
    })

  #--------------------------------------------------------------------------------
  # Private methods
  #

  ###*
  @private
  @method
    Modify property
  @param {string} key
    Key
  @param {Object} value
    Value
  @return {undefined}
  ###
  _modify: (key, value) ->
    return if @[key] == value
    @[key] = value
    @dispatchEvent({type: "change"})
    return

# Post dependencies
# (none)
