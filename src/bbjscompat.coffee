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

