# Pre dependencies
JSONable = require("./jsonable")

###*
@class NamedLink
  Link to named object
@extends JSONable
###
class NamedLink extends JSONable
  null

  #--------------------------------------------------------------------------------
  # Public properties
  #

  ###*
  @property {I18n} friendlyName
    Friendly name of linked object
  @readonly
  ###
  @property("friendlyName", get: -> @_friendlyName)

  ###*
  @property {string} id
    ID of object
  @readonly
  ###
  @property("id", get: -> @_id)

  #--------------------------------------------------------------------------------
  # Event listeners
  #

  ###*
  @event onChange
    Changed event target
  ###
  @property("onChange", get: -> @_onChange)

  #--------------------------------------------------------------------------------
  # Public methods
  #

  ###*
  @method
    Set link
  @param {Object} object to be linked
  @return {undefined}
  ###
  set: (object) ->
    fn = object.friendlyName || object.constructor.friendlyName
    unless fn instanceof I18n
      throw Error("Object should have I18n friendlyName property.")
    id = object.id
    unless typeof(id) == "string"
      throw Error("Object should have string `id' property.")

    @_friendlyName = fn
    @_id = id
    @_onChange.dispatchEvent(this)
    return

  #--------------------------------------------------------------------------------
  # Protected methods
  #

  ###*
  @method constructor
    Constructor of NamedLink class
  @param {Object} obj
    JSON object
  ###
  constructor: (obj) ->
    super(obj)
    @_friendlyName  = I18n.parseJSON(obj.friendlyName)
    @_id            = "#{obj.id || ""}"
    @_onChange      = new EventTarget()
    return

  ###*
  @method
    Convert to JSON object
  @return {Object}
  ###
  toJSON: ->
    return super().extends({
      friendlyName  : @_friendlyName
      id            : @_id
    })

module.exports = NamedLink

# Post dependencies
I18n = require("./i18n")
EventTarget = require("./eventtarget")
