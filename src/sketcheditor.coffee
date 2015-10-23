###*
@class Rubic.SketchEditor
  Editor for sketch configuration (View)
@extends Rubic.Editor
###
class Rubic.SketchEditor extends Rubic.Editor
  DEBUG = Rubic.DEBUG or 0
  Rubic.Editor.addEditor(this)

  ###*
  @method constructor
    Constructor
  @param {Rubic.WindowController} controller
    Controller for this view
  @param {Rubic.Sketch} sketch
    Sketch for this view
  ###
  constructor: (controller, @_sketch) ->
    super(controller)
    @name = "[Sketch] #{@_sketch.name}"
    return

  ###*
  @inheritdoc Rubic.Editor#load
  ###
  load: (callback) ->
    callback(true)  # TODO
    return

  ###*
  @inheritdoc Rubic.Editor#save
  ###
  save: (callback) ->
    callback(true)  # TODO
    return

  ###*
  @inheritdoc Rubic.Editor#close
  ###
  close: (callback) ->
    super((result) =>
      @_sketch = null if result
      callback(result)
    )
    return

