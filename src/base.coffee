Function::property = (prop, desc) ->
  Object.defineProperty @prototype, prop, desc

Function::pureClass = ->
  throw new Error("#{@constructor.name} cannot be instantiated")

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
  @private
  @method
    Print text to output window
  @param {string} text
    Text to print
  @param {string/undefined} [marker=undefined]
    Class name to mark up
  @return {void}
  ###
  @_printOutput: (text, marker) ->
    sess = @_output.getSession()
    range = new window.ace.Range()
    range.start = {row: sess.getLength()}
    range.start.column = sess.getLine(range.start.row).length
    range.end = sess.insert(range.start, text)
    sess.addMarker(range, marker, "text") if marker
    return

  ###*
  @method
    Print text to output window as stdout
  @param {string} text
    Text to print
  @return {void}
  ###
  @stdout: (text) ->
    @_printOutput(text, "marker-stdout")
    return

  ###*
  @method
    Print text to output window as stderr
  @param {string} text
    Text to print
  @return {void}
  ###
  @stderr: (text) ->
    @_printOutput(text, "marker-stderr")
    return

  @showOutput: =>
    # $("body").addClass("o-toggled")
    # @_output.resize(true)
    return

  $(".action-toggle-output").click(=>
    Editor.focus()
    # $("body").toggleClass("o-toggled")
    # @_output.resize(true)
  )

  ###*
  @method
    Clear output window
  @return {void}
  ###
  @clearOutput: ->
    session = window.ace.createEditSession("", "ace/mode/text")
    session.setUseWrapMode(true)
    @_output.setSession(session)
    return

  $(=>
    # Setup output area
    window.ace.Range or= window.ace.require("ace/range").Range
    @_output = window.ace.edit($("#output")[0])
    @_output.renderer.setShowGutter(false)
    @_output.setTheme("ace/theme/twilight")
    @_output.setShowPrintMargin(false)
    @_output.setReadOnly(true)
    @clearOutput()
  )

###*
@class
Helper class for spin.js with modal backdrop
###
class ModalSpin
  $(=>
    @spin = $("#modal-spin").spin({color: "#fff"})
    @count = 0
  )
  @show: ->
    # console.log("ModalSpin.show(#{@count} -> #{@count+1})")
    @spin.modal({
      show: true
      backdrop: "static"
      keyboard: false
    }) if @count == 0
    @count += 1
  @hide: ->
    # console.log("ModalSpin.hide(#{@count} -> #{@count-1})")
    @count -= 1
    @spin.modal('hide') if @count == 0

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
      delay: 1000
      newest_on_top: true
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

escapeHtml = (content) ->
  TABLE =
    "&": "&amp;"
    "'": "&#39;"
    '"': "&quot;"
    "<": "&lt;"
    ">": "&gt;"
  content.replace(/[&"'<>]/g, (match) -> TABLE[match])

class KeyBind
  ###*
  Add a new key bind
  @param {String}   key       Key combination by "Ctrl+A" like format
  @param {String}   desc      Description of action
  @param {Function} callback  Function called when key pressed
  ###
  @add: (key, desc, callback) ->
    # Get modifier
    mod = [(-> not @altKey), (-> not @ctrlKey), (-> not @shiftKey)]
    key = key.replace('Alt+', -> (mod[0] = (-> @altKey); ''))
    key = key.replace('Ctrl+', -> (mod[1] = (-> @ctrlKey); ''))
    key = key.replace('Shift+', -> (mod[2] = (-> @shiftKey); ''))

    # Get key code
    if key.match(/^[A-Z0-9]$/)
      code = key.charCodeAt(0)
    else
      match = key.match(/^F(\d+)$/)
      if match
        code = parseInt(match[1]) + 0x6f
    if not code
      throw new Error("Unknown key name")

    # Bind to document
    $(document).keydown((event) =>
      return unless event.keyCode == code
      for m in mod
        return unless m.call(event)
      callback(event)
      event.preventDefault()
    )
    @_list.push({key: key, desc: desc})

  ###*
  @private
  List of key binds
  ###
  @_list: []

  ###*
  @private
  Constructor
  ###
  constructor: @pureClass

window.show = (args...) ->
  console.log({show: args})

$("#menu").click(->
  Editor.focus()
  $("#wrapper").toggleClass("s-toggled")
)

