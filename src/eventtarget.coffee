###*
@class Rubic.EventTarget
  Target which holds event listeners and dispatch event
  (This is NOT compatible with EventTarget class in WebAPI interface)
###
class Rubic.EventTarget
  ###*
  @private
  @property {Function[]}
    Array of event listeners
  ###
  _listeners: []

  ###*
  @method
    Add an event listener
  @param {Function} listener
    An event listener to add
  @param {Object/null}  thisObject
    The object to use as this when executing listener
  @return {void}
  ###
  addEventListener: (listener, thisObject) ->
    item = [listener, thisObject]
    @_listeners.push(item) unless @_listeners.includes(item)
    return

  ###*
  @method
    Remove an event listener
  @param {Function} listener
    An event listener to remove
  @param {Object/null}  thisObject
    The object to use as this when executing listener
  @return {void}
  ###
  removeEventListener: (listener, thisObject) ->
    item = [listener, thisObject]
    index = @_listeners.indexOf(item)
    @_listeners.splice(index, 1) if index >= 0
    return

  ###*
  @method
    Dispatch event and call listeners
  @return {void}
  ###
  dispatchEvent: (args...) ->
    @_listeners.forEach((element) ->
      element[0].apply(element[1], args)
    )
    return

