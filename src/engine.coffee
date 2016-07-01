# Pre dependencies
JSONable = require("./jsonable")
I18n = require("./i18n")

###*
@class Engine
  Script execution engine (Model)
@extends JSONable
###
class Engine extends JSONable
  null

  #--------------------------------------------------------------------------------
  # Public properties
  #

  ###*
  @template
  @static
  @property {string} coreName
    Name of engine core
  @readonly
  ###
  @classProperty("coreName", get: -> null)

  ###*
  @template
  @static
  @property {string} langName
    Name of programming language
  @readonly
  ###
  @classProperty("langName", get: -> null)

  ###*
  @template
  @static
  @property {string[]} suffixes
    Array of suffixes
  ###
  @classProperty("suffixes", get: -> null)

  ###*
  @property {string} id
    ID of engine
  @readonly
  ###
  @property("id", get: -> @_id)

  ###*
  @property {string} rubicVersion
    Supported Rubic version
  @readonly
  ###
  @property("rubicVersion", get: -> @_rubicVersion)

  ###*
  @property {I18n} friendlyName
    The name of engine
  @readonly
  ###
  @property("friendlyName", get: -> @_friendlyName)

  ###*
  @property {boolean} beta
    Is a beta feature?
  @readonly
  ###
  @property("beta", get: -> @_beta)

  ###*
  @property {boolean} obsolete
    Is an obsolete feature?
  @readonly
  ###
  @property("obsolete", get: -> @_obsolete)

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
  setup: (sketch, item) ->
    return Promise.reject(Error("Pure method"))

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
  build: (sketch, item) ->
    return Promise.reject(Error("Pure method"))

  #--------------------------------------------------------------------------------
  # Protected methods
  #

  ###*
  @method constructor
    Constructor of this class
  @param {Object} obj
  ###
  constructor: (obj) ->
    @_id = "#{obj.id || ""}"
    @_rubicVersion = "#{obj.rubicVersion || ""}"
    @_friendlyName = I18n.parseJSON(obj.friendlyName)
    @_beta = !!obj.beta
    @_obsolete = !!obj.obsolete
    return

  ###*
  @method
    Convert to JSON object
  @return {Object}
  ###
  toJSON: ->
    return super().extends({
      id: @_id
      rubicVersion: @_rubicVersion
      friendlyName: @_friendlyName
      beta: @_beta
      obsolete: @_obsolete
    })

module.exports = Engine
