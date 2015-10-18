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
  constructor: (controller, @sketch) ->
    super(controller)
    @setName(@sketch.name)
    return

