"use strict"
# Pre dependencies
Destructible = require("./destructible")
require("./primitive")

###*
@class JSONable
  Serializable class to JSON
@extends Destructible
###
module.exports = class JSONable extends Destructible
  null

  #--------------------------------------------------------------------------------
  # Public properties
  #

  ###*
  @property {Function} class
    Constructor of class in Rubic
  @readonly
  ###
  @property("__class__", get: -> @constructor)

  #--------------------------------------------------------------------------------
  # Public methods
  #

  ###*
  @static
  @method jsonable
    Register subclass
  @param {Function} subclass
    Constructor of subclass
  @return {undefined}
  ###
  @jsonable: (subclass) ->
    (@subclasses or= []).push(subclass or @)
    return

  ###*
  @static
  @method
    Parse JSON and generate a new instance
  @param {string/Object} obj
    JSON string or JSON object
  @param {Object[]} args
    Class-specific arguments
  @return {Object} new instance
  ###
  @parseJSON: (obj, args...) ->
    return unless obj?
    obj = JSON.parse(obj) if typeof(obj) == "string"
    c = obj.__class__
    return s.generateFromJSON(obj, args...) for s in (@subclasses or []) when s.name == c
    throw Error("Class #{c} not found")

  ###*
  @static
  @template
  @method
    Generate a new instance from JSON
  @param {Object} obj
    JSON object
  @param {Object[]} args
    Class-specific arguments
  @return {Object} new instance
  ###
  @generateFromJSON: (obj, args...) ->
    return new @(obj, args...)

  ###*
  @template
  @method
    Convert to JSON object
  @return {Object}
  ###
  toJSON: ->
    return {
      __class__: @constructor.name
      extends: (o) ->
        @[k] = v for k, v of o
        return this
    }

  ###*
  @method
    Destroy object
  @return {undefined}
  ###
  destroy: ->
    delete this[k] for k, v of this when @hasOwnProperty(k)
    return

# Post dependencies
# (none)
