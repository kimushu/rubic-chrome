"use strict"
# Pre dependencies
JSONable = require("./jsonable")

###*
@class Engine
  Script execution engine (Model)
@extends JSONable
###
module.exports = class Engine extends JSONable
  null

  #--------------------------------------------------------------------------------
  # Public properties
  #

  ###*
  @template
  @static
  @property {string} friendlyName
    Name of engine
  @readonly
  ###
  @classProperty("coreName", get: -> null)

  ###*
  @template
  @static
  @property {string} languageName
    Name of programming language
  @readonly
  ###
  @classProperty("languageName", get: -> null)

  ###*
  @template
  @static
  @property {Object[]} fileTypes
    Array of file type definition
  ###
  @classProperty("fileTypes", get: -> [])

  #--------------------------------------------------------------------------------
  # Public methods
  #

  ###*
  @template
  @method
    Setup item
  @param {Sketch} sketch
    Sketch which owns the item
  @param {SketchItem}
    Item to build
  @return {Promise}
    Promise object
  @return {SketchItem[]/null} return.PromiseValue
    Array of generated items
  ###
  setup: null # pure virtual

  ###*
  @template
  @method
    Build item
  @param {Sketch} sketch
    Sketch which owns the item
  @param {SketchItem}
    Item to build
  @return {Promise}
    Promise object
  ###
  build: null # pure virtual

  #--------------------------------------------------------------------------------
  # Protected methods
  #

  ###*
  @method constructor
    Constructor of Engine class
  @param {Object} obj
  ###
  constructor: (obj) ->
    super(obj)
    return

  ###*
  @method
    Convert to JSON object
  @return {Object}
  ###
  toJSON: ->
    return super().extends({
    })

# Post dependencies
# (none)
