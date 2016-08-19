# http://bluebirdjs.com/docs/api/promise.delay.html
Promise.delay or= (ms, value) ->
  return new Promise((resolve) ->
    window.setTimeout((-> resolve(value)), ms)
  )

# http://bluebirdjs.com/docs/api/delay.html
Promise::delay or= (ms) ->
  return Promise.delay(ms, this)

# http://bluebirdjs.com/docs/api/finally.html
Promise::finally or= (handler) ->
  return @then(
    (value) ->
      pass = -> Promise.resolve(value)
      return Promise.resolve().then(->
        return handler()
      ).then(pass, pass)
    (error) ->
      pass = -> Promise.reject(error)
      return Promise.resolve().then(->
        return handler()
      ).then(pass, pass)
  )

# http://bluebirdjs.com/docs/api/finally.html
Promise::lastly or= Promise::finally

# http://bluebirdjs.com/docs/api/promise.method.html
Promise.method or= (fn) ->
  return (args...) ->
    return Promise.resolve(
    ).then(=>
      return fn(args...)
    )

# http://bluebirdjs.com/docs/api/spread.html
Promise::spread or= (fulfilledHandler) ->
  return @then((promiseArray) ->
    return Promise.all(promiseArray...)
  ).then((valueArray) ->
    return fulfilledHandler(valueArray...)
  )

# http://bluebirdjs.com/docs/api/tap.html
Promise::tap or= (handler) ->
  return @then(
    (value) ->
      pass = -> Promise.resolve(value)
      return Promise.resolve().then(->
        return handler(value)
      ).then(pass, pass)
  )

# http://bluebirdjs.com/docs/api/timeout.html
Promise.TimeoutError or= class TimeoutError
  constructor: (message) ->
    return new TimeoutError(message) unless this instanceof TimeoutError
    message = "timeout error" unless typeof(message) == "string"
    Object.defineProperty(this, "message", value: message)
    Object.defineProperty(this, "name", value: "TimeoutError")
    if Error.captureStackTrace?
      Error.captureStackTrace(this, @constructor)
    else
      Error.call(this)
    return

# http://bluebirdjs.com/docs/api/timeout.html
Promise::timeout or= (ms, error) ->
  error = new Promise.TimeoutError(error) unless error instanceof Error
  return Promise.race([this, new Promise((resolve, reject) ->
    window.setTimeout((-> reject(error)), ms)
  )])

