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
    Editable (true) or readonly (false)
  @readonly
  ###
  @editable: false

  ###*
  @static
  @inheritable
  @property {boolean} closable
    Is editor closable
  @readonly
  ###
  @closable: true

  ###*
  @property {string} className
    Class name of editor
  @readonly
  ###
  @property("className", get: -> @constructor.name)

  ###*
  @property {boolean} editable
    Editable (true) or readonly (false)
  @readonly
  ###
  @property("editable", get: -> @constructor.editable)

  ###*
  @property {boolean} closable
    Is editor closable
  @readonly
  ###
  @property("closable", get: -> @constructor.closable)

  ###*
  @property {boolean} modified
    Is item modified
  ###
  @property("modified",
    get: -> @_modified
    set: (v) ->
      if !v
        @_modified = false
      else if !@_modified
        @_modified = true
        @dispatchEvent({type: EVENT_CHANGE})
  )

  ###*
  @property {string} title
    Title of this editor
  @readonly
  ###
  @property("title", get: -> @_sketchItem?.path)

  ###*
  @property {Sketch} sketch
    Sketch for this editor
  @readonly
  ###
  @property("sketch", get: -> @_sketch)

  ###*
  @property {SketchItem} sketchItem
    Sketch item for this editor
  @readonly
  ###
  @property("sketchItem", get: -> @_sketchItem)

  ###*
  @property {Element} element
    DOM Element for this editor
  @readonly
  ###
  @property("element", get: -> @_element)

  ###*
  @property {string} id
    ID for DOM element
  ###
  @property("id",
    get: -> @_id or ""
    set: (v) -> @_id = v?.toString() or ""
  )

  #--------------------------------------------------------------------------------
  # Events
  #

  ###*
  @event change.editor
    Content changed
  @param {Object} event
    Event object
  @param {Editor} event.target
    Editor instance
  ###
  @event(EVENT_CHANGE = "change.editor")

  ###*
  @event changetitle.editor
    Title changed
  @param {Object} event
    Event object
  @param {Editor} event.target
    Editor instance
  ###
  @event(EVENT_CHANGETITLE = "changetitle.editor")

  ###*
  @event activate.editor
    Editor activated
  @param {Object} event
    Event object
  @param {Editor} event.target
    Editor instance
  ###
  @event(EVENT_ACTIVATE = "activate.editor")

  ###*
  @event deactivate
    Editor deactivated
  @param {Object} event
    Event object
  @param {Editor} event.target
    Editor instance
  ###
  @event(EVENT_DEACTIVATE = "deactivate.editor")

  ###*
  @event close.editor
    Editor closed
  @param {Object} event
    Event object
  @param {Editor} event.target
    Editor instance
  ###
  @event(EVENT_CLOSE = "close.editor")

  #--------------------------------------------------------------------------------
  # Private variables
  #

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
  @param {SketchItem/string} item
    SketchItem instance or editor name
  @return {Function}
    Constructor of suitable editor class (if not found, returns undefined)
  ###
  @findEditor: (item) ->
    if typeof(item) == "string"
      return c for c in @subclasses when c.name == item
    else
      return c for c in @subclasses when c.supports(item)
    return

  ###*
  @template
  @method
    Load file
  @return {Promise}
    Promise object
  ###
  load: null

  ###*
  @template
  @method
    Save file
  @return {Promise}
    Promise object
  ###
  save: null

  ###*
  @template
  @method
    Activate editor
  @return {Promise}
    Promise object
  ###
  activate: ->
    @$(@element).show() if @element?
    @_active = true
    @dispatchEvent({type: EVENT_ACTIVATE})
    if @_firstActivate
      App.popupInfo(I18n.getMessage("This_content_is_read_only")) unless @editable
      @_firstActivate = false
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
    @_active = false
    @dispatchEvent({type: EVENT_DEACTIVATE})
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
  @return {Promise}
    Promise object
  ###
  close: ->
    @deactivate() if @_active
    @_sketchItem.editor = null
    @dispatchEvent({type: EVENT_CLOSE})
    return Promise.resolve()

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
  @param {SketchItem} _sketchItem
    SketchItem instance
  @param {Element} _element
    Element for this editor
  ###
  constructor: (@$, @_sketch, @_sketchItem, @_element) ->
    @_sketchItem?.editor = this
    @_active = false
    @_modified = false
    @_firstActivate = true
    return

# Post dependencies
App = require("app/app")
I18n = require("util/i18n")
