# Dependencies
UnJSONable = require("./unjsonable")
EventTarget = require("./eventtarget")

###*
@class Editor
  Base class for editors/viewers (View)
@extends UnJSONable
###
class Editor extends UnJSONable
  null

  #--------------------------------------------------------------------------------
  # Public properties
  #

  ###*
  @static
  @inheritable
  @property {boolean} editable
    Editable (true) or viewer only (false)
  @readonly
  ###
  @editable: false

  ###*
  @property {SketchItem} sketchItem
    Sketch item for this editor
  @readonly
  ###
  @property("sketchItem", get: -> @_sketchItem)

  ###*
  @property {Sketch} sketch
    Sketch instance
  @readonly
  ###
  @property("sketch", get: -> @_sketch)

  ###*
  @property {string} path
    Path of file
  @readonly
  ###
  @property("path", get: -> @_path)

  ###*
  @property {Element} element
    DOM Element for this editor
  @readonly
  ###
  @property("element", get: -> @_element)

  ###*
  @event onClose
    Event target triggered when editor closed
  @param {Editor} editor
    An editor instance
  ###
  @property("onClosed", get: -> @_onClosed or= new EventTarget())

  #--------------------------------------------------------------------------------
  # Protected properties
  #

  #--------------------------------------------------------------------------------
  # Public methods
  #

  ###*
  @static
  @method
    Register editor subclass
  @param {Function} subclass
    Constructor of subclass
  @return {undefined}
  ###
  @register: (subclass) ->
    (@subclasses or= []).push(subclass)
    return

  ###*
  @static
  @inheritable
  @method
    Check if the editor supports the file or not
  @param {string} path
    File path
  @return {boolean}
  ###
  @supports: (path) ->
    return false

  ###*
  @static
  @method
    Find suitable editor
  @param {string} path
    File path
  @return {Function}
    Constructor of suitable editor class (if not found, returns undefined)
  ###
  @findEditor: (path) ->
    return c if c.supports(path) for c in @subclasses
    return

  ###*
  @template
  @method
    Load file
  @return {Promise}
    Promise object
  ###
  load: ->
    return Promise.reject(Error("Pure method"))

  ###*
  @template
  @method
    Save file
  @return {Promise}
    Promise object
  ###
  save: ->
    return Promise.reject(Error("Pure method"))

  ###*
  @template
  @method
    Activate editor
  @return {undefined}
  ###
  activate: ->
    @$(@element).show() if @element?
    return

  ###*
  @template
  @method
    Deactivate editor
  @return {undefined}
  ###
  deactivate: ->
    @$(@element).hide() if @element?
    return

  ###*
  @template
  @method
    Focus to editor
  @return {undefined}
  ###
  focus: ->
    return

  ###*
  @template
  @method
    Close editor
  @return {undefined}
  ###
  close: ->
    return

  #--------------------------------------------------------------------------------
  # Protected methods
  #

  ###*
  @protected
  @method constructor
    Constructor of Editor class
  @param {jQuery} $
    jQuery object
  @param {Sketch} _sketch
    Sketch instance
  @param {string} _path
    Path of target file
  @param {Element} _element
    Element for this editor
  ###
  constructor: (@$, @_sketch, @_path, @_element) ->
    return

module.exports = Editor
