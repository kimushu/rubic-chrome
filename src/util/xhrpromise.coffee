# Pre dependencies
# (none)

###*
@class XhrPromise
  Promise-based XMLHttpRequest
###
module.exports = class XhrPromise
  null

  @get: (url, options) ->
    return _get("text", url, options)

  @getAsText: (url, options) ->
    return _get("text", url, options)

  @getAsArrayBuffer: (url, options) ->
    return _get("arraybuffer", url, options)

  @getAsBlob: (url, options) ->
    return _get("blob", url, options)

  @getAsJSON: (url, options) ->
    return _get("json", url, options)

  DEFAULT_OPTIONS = {
    data: null
    timeout: 0
    headers: {}
    user: ""
    password: 0
  }

  _get = (type, url, options = {}) ->
    options.method = "GET"
    return _send(type, url, options)

  _send = (type, url, options = {}) ->
    for k, v of DEFAULT_OPTIONS
      options[k] = v unless options[k]?
    return new Promise((resolve, reject) ->
      xhr = new XMLHttpRequest()
      xhr.onload = -> resolve(xhr)
      xhr.onerror = -> reject(xhr)
      xhr.responseType = type
      xhr.timeout = options.timeout
      xhr.open(options.method, url, true, options.user, options.password)
      xhr.setRequestHeader(k, v) for k, v of options.headers
      xhr.send(options.data)
    ) # return new Promise()

# Post dependencies
# (none)
