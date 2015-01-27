Function::property = (prop, desc) ->
  Object.defineProperty @prototype, prop, desc

AsyncFor = (list, each, done) ->
  done or= -> null
  next = (index, next) ->
    return done() if index >= list.length
    obj = list[index]
    each.apply(
      list[index],
      [(-> next(index + 1, next)),
       (-> done.apply(this, arguments))]
    )
  next(0, next)

class App
  @sketch: null

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

