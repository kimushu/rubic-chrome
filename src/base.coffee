Function::property = (prop, desc) ->
  Object.defineProperty @prototype, prop, desc

Function::pureClass = ->
  throw new Error("#{@constructor.name} cannot be instantiated")

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
  @property {String}
  @nullable
  Last error message
  ###
  @lastError: null

  ###*
  @property {Sketch}
  @nullable
  Current sketch
  ###
  @sketch: null

  ###*
  @property {String}
  Default suffix (language) for new sketches including "." character
  ###
  @defaultSuffix: ".rb"

###*
@class
Helper class for spin.js with modal backdrop
###
class ModalSpin
  $(=> @el = $("#modal-spin").spin({color: "#fff"}))
  @show: ->
    @el.modal({
      show: true
      backdrop: "static"
      keyboard: false
    })
  @hide: ->
    @el.hide()

###*
@class
Helper class for bootstrap-notify ($.notify)
###
class Notify
  @error:   -> @notify(arguments, "danger")
  @warning: -> @notify(arguments, "warning")
  @info:    -> @notify(arguments, "info")
  @success: -> @notify(arguments, "success")
  @notify: ([message, options], type) ->
    $.notify(message, $.extend({
      type: type
      allow_dismiss: true
      placement: {from: "bottom", align: "center"}
      delay: 2000
      offset: 52
    }, options))

class Marshal
  @loadClass: (data, classes) ->
    for c in classes
      continue unless data.classname == c.name
      return c.load(data.content)
    null  # TODO: crash

  @saveClass: (instance) ->
    return {classname: instance.name, content: instance.save()}

