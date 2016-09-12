"use strict"
# Pre dependencies
JSONable = require("util/jsonable")
require("util/primitive")

###*
@class Builder
  Script builder base class (Model)
@extends JSONable
###
module.exports = class Builder extends JSONable
  null

  #--------------------------------------------------------------------------------
  # Public properties
  #

  ###*
  @static
  @template
  @property {Object} template
    Template information
  ###
  @classProperty("template", value: Object.freeze({}))

  ###*
  @property {I18n} friendlyName
    Name of this builder
  @readonly
  ###
  @property("friendlyName", get: -> @constructor.friendlyName)

  ###*
  @property {Object} configurations
    Property information
  ###
  @property("configurations",
    get: -> @constructor.configurations or Object.freeze({})
  )

  ###*
  @property {SketchItem} sketchItem
    SketchItem associated to this builder
  @readonly
  ###
  @property("sketchItem", get: -> @_sketchItem)

  #--------------------------------------------------------------------------------
  # Public methods
  #

  ###*
  @template
  @static
  @method
    Check if this builder supports the file
  @param {string} name
    File name
  @return {boolean}
    true if supports
  ###
  @supports: null

  ###*
  @template
  @method
    Setup
  @return {Promise}
    Promise object
  ###
  setup: null

  ###*
  @template
  @method
    Build
  @param {Promise}
    Promise object
  ###
  build: null

  #--------------------------------------------------------------------------------
  # Protected methods
  #

  ###*
  @protected
  @method constructor
    Constructor of Builder class
  @param {Object} obj
    JSON object
  @param {SketchItem} _sketchItem
    SketchItem instance associated to this builder
  ###
  constructor: (obj = {}, @_sketchItem) ->
    super(obj)
    return

  ###*
  @protected
  @inheritdoc JSONable#toJSON
  ###
  toJSON: ->
    return super().extends({
    })

# Post dependencies
# (none)
