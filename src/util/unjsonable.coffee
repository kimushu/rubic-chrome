"use strict"
# Pre dependencies
Destructible = require("./destructible")

###*
@class UnJSONable
  Unserializable class to JSON
@extends Destructible
###
module.exports = class UnJSONable extends Destructible
  null

  #--------------------------------------------------------------------------------
  # Public methods
  #

  ###*
  @method
    Convert to JSON object (Always refuse by returning undefined)
  @return {undefined}
  ###
  toJSON: ->
    return

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
