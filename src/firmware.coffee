# Pre dependencies
JSONable = require("./jsonable")

###*
@class Firmware
  Embedded board firmware class (Model)
@extends JSONable
###
class Firmware extends JSONable
  Firmware.jsonable()

  #--------------------------------------------------------------------------------
  # Public properties
  #

  #--------------------------------------------------------------------------------
  # Public methods
  #

  ###*
  @method constructor
    Constructor of Firmware class
  @param {Object} obj
    JSON object
  ###
  constructor: (obj) ->
    @_id            = "#{obj.id || ""}"
    @_rubicVersion  = "#{obj.rubicVersion || ""}"
    @_friendlyName  = I18n.parseJSON(obj.friendlyName)
    @_beta          = !!obj.beta
    @_obsolete      = !!obj.obsolete
    @_assets        = {}
    for k, v of (obj.assets or {})
      @_assets[k] = "#{v || ""}"
    return

  ###*
  @method
    Convert to JSON object
  @return {Object}
  ###
  toJSON: ->
    return super().extends({
      id            : @_id
      friendlyName  : @constructor.friendlyName
      rubicVersion  : @constructor.rubicVersion
      beta          : @_beta
      obsolete      : @_obsolete
      assets        : @_assets
    })

module.exports = Firmware

# Post dependencies
# (none)
