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
  @property {Builder} builder
    Builder instance to process this item
  ###
  @property("builder",
    get: -> @_builder
    set: (v) -> @_modify =>
      @_builder = v
      return true
  )

  ###*
  @property {I18n} fileType
    File type description
  ###
  @property("fileType",
    get: -> @_fileType
    set: (v) -> @_modify =>
      @_fileType = v
      return true
  )

  ###*
  @property {SketchItem} source
    Source item instance
  ###
  @property("source",
    get: -> @_sketch.getItem(@_sourcePath) if @_sourcePath?
    set: (v) -> @_modify =>
      @_sourcePath = v?.path
      return true
  )

  ###*
  @property {string} sourcePath
    Source path
  @readonly
  ###
  @property("sourcePath", get: -> @_sourcePath)

  ###*
  @property {boolean} transfer
    Is this item transfered to the board
  ###
  @property("transfer",
    get: -> @_transfer,
    set: (v) -> @_modify =>
      @_transfer = !!v
      return true
  )

  ###*
  @property {Editor} editor
    The editor for this item
  ###
  @property("editor",
    get: -> @_editor,
    set: (v) ->
      @_editor?.removeEventListener("change.editor", this)
      @_editor = v
      @_editor?.addEventListener("change.editor", this)
  )

  ###*
  @property {number} lastModified
    Timestamp of last modified date (in milliseconds from epoch, UTC)
  @readonly
  ###
  @property("lastModified", get: -> @_lastModified or 0)

  ###*
  @property {number} lastTransfered
    Timestamp of last transfered date (in milliseconds from epoch, UTC)
  @readonly
  ###
  @property("lastTransfered", get: -> @_lastTransfered or 0)

  #--------------------------------------------------------------------------------
  # Events
  #

  ###*
  @event change.sketchitem
    SketchItem changed (excludes content's change)
  @param {Object} event
    Event object
  @param {SketchItem} event.target
    SketchItem instance
  ###
  @event(EVENT_CHANGE = "change.sketchitem")

  ###*
  @event contentchange.sketchitem
    Content of SketchItem changed
  @param {Object} event
    Event object
  @param {SketchItem} event.target
    SketchItem instance
  ###
  @event(EVENT_CONTENTCHANGE = "contentchange.sketchitem")

  ###*
  @event contentsave.sketchitem
    Content of SketchItem saved
  @param {Object} event
    Event object
  @param {SketchItem} event.target
    SketchItem instance
  ###
  @event(EVENT_CONTENTSAVE = "contentsave.sketchitem")

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
    @_builder = Builder.parseJSON(obj.builder, this)
    @_fileType = I18n.parseJSON(obj.fileType)
    @_sourcePath = obj.sourcePath
    @_transfer = !!obj.transfer
    @_editor = null
    return

  ###*
  @inheritdoc JSONable#toJSON
  ###
  toJSON: ->
    return super().extends({
      path: @_path
      builder: @_builder
      fileType: @_fileType
      sourcePath: @_sourcePath
      transfer: @_transfer
    })

  ###*
  @method
    Event handler
  @param {Object} event
    Event object
  @return {undefined}
  ###
  handleEvent: (event) ->
    switch event.type
      when "change.editor"
        @dispatchEvent({type: EVENT_CONTENTCHANGE})
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
      @_lastModified = Date.now()
      @dispatchEvent({type: EVENT_CONTENTSAVE})
      return
    )

  ###*
  @method
    Remove content
  @return {Promise}
    Promise object
  ###
  removeContent: ->
    return Promise.reject(Error("No sketch")) unless @_sketch?
    return @_sketch.dirFs.unlink(@_path).then(=>
      @_lastModified = 0
      return
    )

  ###*
  @method
    Set transfered
  @return {undefined}
  ###
  setTransfered: ->
    @_lastTransfered = Date.now()
    return

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
    ).catch((error) =>
      return  # Ignore error on readContent
    ).then((content) =>
      @_path = newPath
      return unless content?
      return @writeContent(content)
    ).then(=>
      return unless content?
      return @_sketch.dirFs.unlink(oldPath)
    ).then(=>
      return  # Last PromiseValue
    ).catch((error) =>
      @_path = oldPath
      return Promise.reject(error)
    ) # return Promise.resolve().then()...

  #--------------------------------------------------------------------------------
  # Private methods
  #

  ###*
  @private
  @method
    Notify modifications
  @param {Function} callback
    Callback function
  @return {undefined}
  ###
  _modify: (callback) ->
    return unless callback.call(this)?
    @_modified = true
    @dispatchEvent({type: EVENT_CHANGE})
    return

# Post dependencies
Builder = require("builder/builder")
I18n = require("util/i18n")
