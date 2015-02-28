Function::property = (prop, desc) ->
  Object.defineProperty @prototype, prop, desc

#  AsyncFor = (list, each, done) ->
#    done or= -> null
#    next = (index, next) ->
#      return done() if index >= list.length
#      obj = list[index]
#      each.apply(
#        list[index],
#        [(-> next(index + 1, next)),
#         (-> done.apply(this, arguments))]
#      )
#    next(0, next)
#  
#  Object.defineProperty(Object.prototype, "Sequence", {value: ->
#    {
#      jobs: arguments,
#      self: this,
#      index: 0,
#      finished: false,
#      aborted: false,
#      onFinished: null,
#      onAborted: null,
#      next: ->
#        @index += 1
#        if (@index >= @jobs.length)
#          @finished = true
#          return (@onFinished or (-> null)).apply(@self, arguments)
#        @jobs[@index].apply(@self, arguments)
#      abort: ->
#        @aborted = true
#        (@onAborted or (-> null)).apply(@self, arguments)
#      start: ->
#        @index = -1
#        @next.apply(this, arguments)
#    }
#  })
#  
#  Object.defineProperty(Object.prototype, "Iterator", {value: ->
#    {
#      jobs: arguments,
#      self: this,
#      index: 0,
#      finished: false,
#      aborted: false,
#      onFinished: null,
#      onAborted: null,
#      next: ->
#        @index += 1
#        if (@index >= @jobs.length)
#          @finished = true
#          return (@onFinished or (-> null)).apply(@self)
#        @onWalk.apply(@self, @jobs[@index])
#      abort: ->
#        @aborted = true
#        (@onAborted or (-> null)).apply(@self, arguments)
#      walk: ->
#        @onWalk = arguments[0]
#        @index = -1
#        @next()
#    }
#  })

class App
  ###*
  @property {Sketch} sketch
  Current sketch
  ###
  @sketch: null

  ###*
  @property {String} defaultSuffix
  Default suffix (language) for new sketches including "." character
  ###
  @defaultSuffix: ".rb"

class ModalSpin
  $(=> @el = $("#modal-spin").spin({color: "#fff"}))
  @show: ->
    @el.modal({
      show: true,
      backdrop: "static",
      keyboard: false,
    })
  @hide: ->
    @el.hide()

###*
Async method invoker (serial version)
@param list             List of objects to walk
@param invoker          Invoke method for each object
@param successCallback  Callback on success (no_argument)
@param errorCallback    Callback on error (failed_object)
###
serialInvoker = (list, invoker, successCallback, errorCallback) ->
  errorCallback or= -> null
  next = (index, next) ->
    return successCallback() if index >= list.length
    obj = list[index]
    invoker.apply(obj, [(-> next(index + 1, next)), (-> errorCallback(obj))])
  next(0, next)

###*
Async method invoker (parallel version)
@param list             List of objects to walk
@param invoker          Invoke method for each object
@param successCallback  Callback on success (no_argument)
@param errorCallback    Callback on error (list_of_failed_objects)
###
parallelInvoker = (list, invoker, successCallback, errorCallback) ->
  errorCallback or= -> null
  count = list.length
  failed = []
  next = (obj) ->
    count -= 1
    failed.push(obj) if obj
    if count > 0
      null
    else if failed.length > 0
      errorCallback(failed)
    else
      successCallback()
  for obj in list
    do (obj) ->
      invoker.apply(obj, [(-> next()), (-> next(obj))])

class Marshal
  @loadClass: (data, classes) ->
    for c in classes
      continue unless data.classname == c.name
      return c.load(data.content)
    null  # TODO: crash

  @saveClass: (instance) ->
    return {classname: instance.name, content: instance.save()}

