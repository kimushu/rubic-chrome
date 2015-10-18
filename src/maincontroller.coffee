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
  @property {Rubic.Editor[]}
    List of editors
  ###
  editors: []

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
    @$("#wrapper").toggleClass("toggled")
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
          callback: ->
            callback(true)
        }
        no: {
          label: Rubic.I18n("NoXpIWantToCancelToSaveXp")
          className: "btn-success"
          callback: =>
            @_notify("info", Rubic.I18n("Cancelled"))
            callback(false)
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
    new Function.Sequence(
      (seq) =>
        return seq.next() unless @sketch?.modified
        @_confirmDiscardSketch((discard) =>
          return seq.next(discard)
        )
      (seq) =>
        Rubic.Sketch.create((result, sketch) =>
          return seq.abort() unless result
          @_setSketch(sketch, (result) ->
            return seq.next(result)
          )
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
    entry = null
    new Function.Sequence(
      (seq) =>
        return seq.next() unless @sketch?.modified
        @_confirmDiscardSketch((discard) =>
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
          @_setSketch(sketch, (result) ->
            return seq.next(result)
          )
        )
    ).start()
    return

  ###*
  @private
  @method
    Set current sketch
  @param {Rubic.Sketch} sketch
    Sketch instance to set
  @param {function(boolean):void} callback
    Callback function with result
  @return {void}
  ###
  _setSketch: (sketch, callback) ->
    editors = null
    new Function.Sequence(
      (seq) =>
        return seq.next() unless @editors.length > 0
        editor = @editors.shift()
        editor.close((result) ->
          return seq.abort() unless result
          return seq.redo()
        )
      (seq) =>
        return seq.next() unless @sketch
        @sketch.close((result) ->
          return seq.next(result)
        )
      (seq) =>
        editors = [new Rubic.SketchEditor(this, sketch)]
        name = sketch.bootFile or ""
        return seq.next() unless name != ""
        unless sketch.files[name]
          @_notify("warning", "#{Rubic.I18n("BootScriptIsNotRegisteredInThisSketchXc")}#{name}")
          return seq.next()
        sketch.dirEntry.getFile(
          name
          {}
          (fileEntry) =>
            editor = Rubic.Editor.createEditor(this, fileEntry)
            if editor
              editors.push(editor)
            else
              @_notify("warning", "#{Rubic.I18n("CannotGuessEditorForXc")}#{name}")
            return seq.next()
          =>
            @_notify("warning", "#{Rubic.I18n("CannotOpenFileXc")}#{name}")
            return seq.next()
        )
      (seq) =>
        @sketch = sketch
        @editors = editors
        return seq.next()
      (seq) =>
        @editors[@editors.length - 1].activate((result) ->
          return seq.next()
        )
    ).final(
      (seq) ->
        callback(seq.finished)
    ).start()
    return

