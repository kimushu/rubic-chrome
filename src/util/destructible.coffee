"use strict"
# Pre dependencies
# (none)

###*
@class Destructible
  Destructible object
@extends Destructible
###
module.exports = class Destructible
  null

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
