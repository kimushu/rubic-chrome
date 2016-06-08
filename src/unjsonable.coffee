# browserify ready
###*
@class UnJSONable
  Unserializable class to JSON
###
class UnJSONable
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

module.exports = UnJSONable
