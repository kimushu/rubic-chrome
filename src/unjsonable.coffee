"use strict"
# Pre dependencies
# (none)

###*
@class UnJSONable
  Unserializable class to JSON
###
module.exports = class UnJSONable
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

# Post dependencies
# (none)
