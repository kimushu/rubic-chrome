"use strict"
# Pre dependencies
UnJSONable = require("util/unjsonable")
require("util/primitive")

###*
@class Editor
  Base class for editors/viewers (View)
@extends UnJSONable
###
module.exports = class Editor extends UnJSONable
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
  @property {string} title
    Title of this editor
  @readonly
  ###
  @property("title", get: -> @_item?.path)

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
  @property {SketchItem} item
    SketchItem instance
  @readonly
  ###
  @property("item", get: -> @_item)

  ###*
  @property {Element} element
    DOM Element for this editor
  @readonly
  ###
  @property("element", get: -> @_element)

  ###*
  @property {string} uniqueId
    Unique ID for editor management
  @readonly
  ###
  @property("uniqueId", get: -> @_uniqueId)

  #--------------------------------------------------------------------------------
  # Events
  #

  ###*
  @event changeTitle
    Title changed
  @param {Object} event
    Event object
  @param {Editor} event.target
    Editor instance
  ###
  @event("changeTitle")

  ###*
  @event activate
    Editor activated
  @param {Object} event
    Event object
  @param {Editor} event.target
    Editor instance
  ###
  @event("activate")

  ###*
  @event deactivate
    Editor deactivated
  @param {Object} event
    Event object
  @param {Editor} event.target
    Editor instance
  ###
  @event("deactivate")

  ###*
  @event close
    Editor closed
  @param {Object} event
    Event object
  @param {Editor} event.target
    Editor instance
  ###
  @event("close")

  #--------------------------------------------------------------------------------
  # Private variables
  #

  nextUniqueId = 1

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
  @param {SketchItem} item
    SketchItem instance
  @return {boolean}
  ###
  @supports: (item) ->
    return false

  ###*
  @static
  @method
    Find suitable editor
  @param {SketchItem} Item
    SketchItem instance
  @return {Function}
    Constructor of suitable editor class (if not found, returns undefined)
  ###
  @findEditor: (item) ->
    return c for c in @subclasses when c.supports(item)
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
  @return {Promise}
    Promise object
  ###
  activate: ->
    @$(@element).show() if @element?
    @dispatchEvent({type: "activate"})
    return Promise.resolve()

  ###*
  @template
  @method
    Deactivate editor
  @return {Promise}
    Promise object
  ###
  deactivate: ->
    @$(@element).hide() if @element?
    @dispatchEvent({type: "deactivate"})
    return Promise.resolve()

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
  @param {SketchItem} _item
    SketchItem instance
  @param {Element} _element
    Element for this editor
  ###
  constructor: (@$, @_sketch, @_item, @_element) ->
    @_uniqueId = "Editor_ID_#{nextUniqueId++}"
    return

# Post dependencies
# (none)
