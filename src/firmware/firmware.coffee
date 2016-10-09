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
    @_beta          = !!obj.beta
    @_obsolete      = !!obj.obsolete
    @_boardSpecific = obj.boardSpecific or {}
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
      beta          : @_beta
      obsolete      : @_obsolete
      boardSpecific : @_boardSpecific
    })

# Post dependencies
I18n = require("util/i18n")
