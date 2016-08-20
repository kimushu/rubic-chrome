"use strict"
# Pre dependencies
JSONable = require("util/jsonable")
require("util/primitive")

###*
@class Firmware
  Embedded board firmware class (Model)
@extends JSONable
###
module.exports = class Firmware extends JSONable
  Firmware.jsonable()

  #--------------------------------------------------------------------------------
  # Public properties
  #

  ###*
  @property {string} id
    ID of this firmware
  @readonly
  ###
  @property("id", get: -> @_id)

  ###*
  @property {I18n} friendlyName
    The name of firmware
  @readonly
  ###
  @property("friendlyName", get: -> @_friendlyName)

  ###*
  @property {string} rubicVersion
    Supported Rubic version
  @readonly
  ###
  @property("rubicVersion", get: -> @_rubicVersion)

  ###*
  @property {I18n} author
    Author of this firmware
  @readonly
  ###
  @property("author", get: -> @_author)

  ###*
  @property {Engine[]} engines
    List of engines
  @readonly
  ###
  @property("engines", get: -> (e for e in @_engines))

  ###*
  @property {FileHandler[]) fileHandlers
    List of file handlers by all engines
  @readonly
  ###
  @property("fileHandlers", get: ->
    return @_fileHandlers or= @_engines.reduce(
      (handlers, engine) => handlers.concat(engine.fileHandlers)
      []
    )
  )

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
  @method constructor
    Constructor of Firmware class
  @param {Object} obj
    JSON object
  ###
  constructor: (obj = {}) ->
    @_id            = obj.id?.toString()
    @_friendlyName  = I18n.parseJSON(obj.friendlyName)
    @_rubicVersion  = obj.rubicVersion?.toString()
    @_author        = I18n.parseJSON(obj.author)
    @_engines       = (Engine.parseJSON(e) for e in (obj.engines or []))
    @_beta          = !!obj.beta
    @_obsolete      = !!obj.obsolete
    return

  ###*
  @method
    Convert to JSON object
  @return {Object}
  ###
  toJSON: ->
    return super().extends({
      id            : @_id
      friendlyName  : @_friendlyName
      rubicVersion  : @_rubicVersion
      author        : @_author
      engines       : @_engines
      beta          : @_beta
      obsolete      : @_obsolete
    })

# Post dependencies
I18n = require("util/i18n")
Engine = require("engine/engine")
