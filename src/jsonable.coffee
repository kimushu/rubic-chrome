# browserify ready
###*
@class Rubic.JSONable
  Serializable class to JSON
###
class JSONable
  null

  #--------------------------------------------------------------------------------
  # Public properties
  #

  ###*
  @property {Function} class
    Constructor of class in Rubic
  @readonly
  ###
  @property("class", get: -> @constructor)

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
  @return {Object} new instance
  ###
  @parseJSON: (obj) ->
    obj = JSON.parse(obj) if typeof(obj) == "string"
    c = obj.class
    return s.generateFromJSON(obj) for s in (@subclasses or []) when s.name == c
    throw Error("Class #{obj.class} not found")

  ###*
  @static
  @method
    Generate a new instance from JSON
  @param {Object} obj
    JSON object
  @return {Object} new instance
  ###
  @generateFromJSON: (obj) ->
    return new @(obj)

  ###*
  @method
    Convert to JSON object
  @return {Object}
  ###
  toJSON: ->
    return {
      class: @constructor.name
      extends: (o) ->
        @[k] = v for k, v of o
        return this
    }

module.exports = JSONable
