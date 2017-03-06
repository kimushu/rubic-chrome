"use strict"
###*
Function decorator to delay callback

@method delayed
@param {number} delay
  Delay in milliseconds
@param {function} callback
  Callback function to be invoked after delay
@return {function}
  Decorated function
###
module.exports =
delayed = (delay, callback) ->
  f = (args...) ->
    global.clearTimeout(f._timerId) if f._timerId?
    f._timerId = global.setTimeout(
      ->
        f._timerId = null
        callback(args...)
      delay
    )
  return f
