###*
@class Rubic.MainController
  Controller for main window (Singleton, Controller)
@extends Rubic.WindowController
###
class Rubic.MainController extends Rubic.WindowController
  DEBUG = Rubic.DEBUG or 0

  ###*
  @property {Rubic.Sketch}
    Instance of current sketch
  ###
  sketch: null

  ###*
  @method
    Start controller
  @return {void}
  ###
  start: ->
    super(
      "win_main.html"
      {
        innerBounds: {
          width: 640
          height: 480
          minWidth: 480
        }
      }
      =>
        @window.app.main = this
    )
    return

  ###*
  @protected
  @method
    Event handler on document.onload
  @return {void}
  ###
  onload: ->
    super()
    @$(".act-toggle-menu"   ).click(=> @_toggleMenu())
    @$(".act-new-sketch"    ).click(=> @_newSketch())
    @$(".act-open-sketch"   ).click(=> @_openSketch())
    @$(".act-save-sketch"   ).click(=> @_saveSketch())
    @$(".act-save-sketch-as").click(=> @_saveSketchAs())
    @$(".act-build-sketch"  ).click(=> @_buildSketch())
    @$(".act-run-sketch"    ).click(=> @_runSketch())
    @$(".act-debug-sketch"  ).click(=> @_debugSketch())
    return

  ###*
  @private
  @method
    Show dialog box (bootbox.dialog)
  @param {Object} options
    Options passed to bootbox.dialog
  @return {void}
  ###
  _dialog: (options) ->
    @window.bootbox.dialog(options)
    return

  ###*
  @private
  @method
    Generate popup notify message (bootstrap-notify)
  @param {"success"/"info"/"warning"/"danger"}  type
    Type of message
  @param {string} message
    Message text
  @param {Object} options
    Other options to bootstrap-notify
  @return {void}
  ###
  _notify: (type, message, options) ->
    @$.notify(message, @$.extend({
      type: type
      allow_dismiss: true
      placement: {from: "bottom", align: "center"}
      delay: 2000
      newest_on_top: true
      offset: 52
    }, options))
    return

  ###*
  @private
  @method
    Toggle menubar
  @return {void}
  ###
  _toggleMenu: ->
    @$("#menubar").toggleClass("toggled")
    return

  ###*
  @private
  @method
    Confirm discarding current sketch
  @param {function(boolean):void} callback
    Callback function
  @param {boolean} callback.discard
    Yes to discard
  @return {void}
  ###
  _confirmDiscardSketch: (callback) ->
    @_dialog({
      title: Rubic.I18n("CurrentSketchHasBeenModified")
      message: Rubic.I18n("AreYouWantToDiscardModificationsXq")
      buttons: {
        yes: {
          label: Rubic.I18n("YesXpIDiscardThemXp")
          className: "btn-danger"
          callback: -> callback(true)
        }
        no: {
          label: Rubic.I18n("NoXpIWantToCancelToSaveXp")
          className: "btn-success"
          callback: -> callback(false)
        }
      }
    })
    return

  ###*
  @private
  @method
    Create new sketch
  @return {void}
  ###
  _newSketch: ->
    @sketch = {modified: true}
    new Function.Sequence(
      (seq) =>
        return seq.next() unless @sketch?.modified
        @_confirmDiscardSketch((discard) =>
          @_notify("info", Rubic.I18n("Cancelled")) unless discard
          return seq.next(discard)
        )
      (seq) =>
        Rubic.Sketch.create((result, sketch) =>
          return seq.abort() unless result
          @_setSketch(sketch)
          return seq.next()
        )
    ).start()
    return

  ###*
  @private
  @method
    Open another sketch
  @return {void}
  ###
  _openSketch: ->
    @sketch = {modified: true}
    entry = null
    new Function.Sequence(
      (seq) =>
        return seq.next() unless @sketch?.modified
        @_confirmDiscardSketch((discard) =>
          @_notify("info", Rubic.I18n("Cancelled")) unless discard
          return seq.next(discard)
        )
      (seq) =>
        @window.chrome.fileSystem.chooseEntry({type: "openDirectory"}, (dirEntry) ->
          unless dirEntry
            # cancelled by user
            @window.chrome.runtime.lastError
            return seq.abort()
          entry = dirEntry
          return seq.next()
        )
      (seq) =>
        Rubic.Sketch.open(entry, (result, sketch) =>
          return seq.abort() unless result
          @_setSketch(sketch)
          return seq.next()
        )
    ).start()
    return

