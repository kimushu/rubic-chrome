# http://bluebirdjs.com/docs/api/promise.delay.html
unless Promise.delay
  Promise.delay = (ms, value) ->
    return new Promise((resolve) ->
      window.setTimeout((-> resolve(value)), ms)
    )

# http://bluebirdjs.com/docs/api/delay.html
unless Promise::delay
  Promise::delay = (ms) ->
    return Promise.delay(ms, this)

# http://bluebirdjs.com/docs/api/finally.html
unless Promise::finally
  Promise::finally = (handler) ->
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
unless Promise::lastly
  Promise::lastly = Promise::finally

# http://bluebirdjs.com/docs/api/spread.html
unless Promise::spread
  Promise::spread = (fulfilledHandler) ->
    return @then((promiseArray) ->
      return Promise.all(promiseArray...)
    ).then((valueArray) ->
      return fulfilledHandler(valueArray...)
    )

# http://bluebirdjs.com/docs/api/tap.html
unless Promise::tap
  Promise::tap = (handler) ->
    return @then(
      (value) ->
        pass = -> Promise.resolve(value)
        return Promise.resolve().then(->
          return handler()
        ).then(pass, pass)
    )

# http://bluebirdjs.com/docs/api/timeout.html
unless Promise.TimeoutError
  class TimeoutError
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
  Promise.TimeoutError = TimeoutError

# http://bluebirdjs.com/docs/api/timeout.html
unless Promise::timeout
  Promise::timeout = (ms, error) ->
    error = new Promise.TimeoutError(error) unless error instanceof Error
    return Promise.race([this, new Promise((resolve, reject) ->
      window.setTimeout((-> reject(error)), ms)
    )])

