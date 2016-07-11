# Pre dependencies
Editor = require("./editor")

###*
@class SketchEditor
  Editor for sketch configuration (View)
@extends Editor
###
class SketchEditor extends Editor
  Editor.register(this)

  #--------------------------------------------------------------------------------
  # Public properties
  #

  ###*
  @property {string} title
    Title of this editor
  @readonly
  ###
  @property("title", get: -> @sketch.friendlyName)

  #--------------------------------------------------------------------------------
  # Private variables
  #

  domElement = null

  #--------------------------------------------------------------------------------
  # Public methods
  #

  ###*
  @method constructor
    Constructor
  @param {jQuery} $
    jQuery object
  @param {Sketch} _sketch
    Sketch instance
  ###
  constructor: ($, sketch) ->
    super($, sketch, null, (domElement or= $("#sketch-editor")[0]))
    return

module.exports = SketchEditor

# Post dependencies
# (none)
