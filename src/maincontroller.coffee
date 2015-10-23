###*
@class Rubic.MainController
  Controller for main window (Singleton, Controller)
@extends Rubic.WindowController
###
class Rubic.MainController extends Rubic.WindowController
  DEBUG = Rubic.DEBUG or 0

  ###*
  @property {Rubic.Sketch} sketch
    Instance of current sketch
  @readonly
  ###
  @property("sketch", get: -> @_sketch)

  ###*
  @method constructor
    Constructor of MainController
  ###
  constructor: ->
    @_sketch = null
    @_editors = []
    @_locked = false

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
  @private
  @method
    Acquire lock
  @return {boolean}
    - true: success
    - false: already locked
  ###
  _lock: ->
    return false if @_locked
    return (@_locked = true)

  ###*
  @private
  @method
    Release lock
  @return {void}
  ###
  _unlock: ->
    @_locked = false
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
          label: Rubic.I18n("NoXpIWantToCancelXp")
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
    Confirm overwriting non-empty directory
  @param {function(boolean):void} callback
    Callback function
  @param {boolean} callback.overwrite
    Yes to discard
  @return {void}
  ###
  _confirmOverwriteDirectory: (callback) ->
    @_dialog({
      title: Rubic.I18n("SelectedFolderIsNotEmpty")
      message: Rubic.I18n("WouldYouLikeToOverwriteExistingFilesXq")
      buttons: {
        yes: {
          label: Rubic.I18n("YesXpOverwriteThemXp")
          className: "btn-danger"
          callback: ->
            callback(true)
        }
        no: {
          label: Rubic.I18n("NoXpIWantToCancelXp")
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
    return unless @_lock()
    # @sketch = {modified: true}
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
    ).final(
      (seq) =>
        @_unlock()
    ).start()
    return

  ###*
  @private
  @method
    Open another sketch
  @return {void}
  ###
  _openSketch: ->
    return unless @_lock()
    entry = null
    new Function.Sequence(
      (seq) =>
        return seq.next() unless @sketch?.modified
        @_confirmDiscardSketch((discard) =>
          return seq.next(discard)
        )
      (seq) =>
        @window.chrome.fileSystem.chooseEntry({type: "openDirectory"}, (dirEntry) =>
          unless dirEntry
            # cancelled by user
            @window.chrome.runtime.lastError
            @_notify("info", Rubic.I18n("Cancelled"))
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
    ).final(
      (seq) =>
        @_unlock()
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
    new Function.Sequence(
      (seq) =>
        return seq.next() unless @_editors.length > 0
        editor = @_editors[0]
        @_removeEditor(editor)
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
        editor = new Rubic.SketchEditor(this, sketch)
        @_addEditor(editor)
        editor.load((result) =>
          unless result
            @_notify("warning", Rubic.I18n("CannotLoadSketchEditor"))
          return seq.next()
        )
      (seq) =>
        name = sketch.bootFile or ""
        return seq.next() unless name != ""
        unless sketch.getFiles().includes(name)
          @_notify("warning", "#{Rubic.I18n("BootScriptIsNotRegisteredInThisSketchXc")}#{name}")
          return seq.next()
        sketch.dirEntry.getFile(
          name
          {}
          (fileEntry) =>
            editor = Rubic.Editor.createEditor(this, fileEntry)
            unless editor
              @_notify("warning", "#{Rubic.I18n("CannotGuessEditorForXc")}#{name}")
              return seq.next()
            @_addEditor(editor)
            editor.load((result) =>
              unless result
                @_notify("warning", "#{Rubic.I18n("CannotLoadEditorForXc")}#{name}")
              return seq.next()
            )
          =>
            @_notify("warning", "#{Rubic.I18n("CannotOpenFileXc")}#{name}")
            return seq.next()
        )
      (seq) =>
        @_sketch = sketch
        console.log({info: "Sketch loaded", data: sketch})
        return seq.next()
      (seq) =>
        @_editors[@_editors.length - 1].activate((result) ->
          return seq.next()
        )
    ).final(
      (seq) ->
        callback(seq.finished)
    ).start()
    return

  ###*
  @private
  @method
    Select an editor
  @param {Rubic.Editor} editor
    The instance of editor to select
  @return {void}
  ###
  _selectEditor: (editor) ->
    editor.activate((result) ->
      unless result
        @_notify("danger", "#{Rubic.I18n("CannotActivateEditorForFileXc")}#{editor.name}")
    )
    return

  ###*
  @private
  @method
    Add an editor
  @param {Rubic.Editor} editor
    The instance of editor to add
  @return {void}
  ###
  _addEditor: (editor) ->
    editor.onSelectRequest.addEventListener(@_selectEditor, this)
    @_editors.push(editor)
    return

  ###*
  @private
  @method
    Remove an editor
  @param {Rubic.Editor} editor
    The instance of editor to remove
  @return {void}
  ###
  _removeEditor: (editor) ->
    index = @_editors.indexOf(editor)
    @_editors.splice(index, 1) if index >= 0
    editor.onSelectRequest.removeEventListener(@_selectEditor, this)
    return

  ###*
  @private
  @method
    Save sketch (overwrite)
  @return {void}
  ###
  _saveSketch: ->
    return unless @_lock()
    editors = null
    new Function.Sequence(
      (seq) =>
        editors or= @_editors
        return seq.next() unless editors.length > 0
        editor = editors.shift()
        return seq.redo() unless editor.modified
        editor.save((result) =>
          return seq.redo() if result
          @_notify("danger", "#{Rubic.I18n("CannotSaveXc")}#{editor.name}")
          return seq.abort()
        )
      (seq) =>
        @sketch.save((result) =>
          return seq.next() if result
          @_notify("danger", "#{Rubic.I18n("FailedToSaveSketch")}")
          return seq.abort()
        )
    ).final(
      (seq) =>
        if seq.finished
          @_notify("success", Rubic.I18n("TheSketchHasBeenSavedXp"))
        @_unlock()
    ).start()
    return

  ###*
  @private
  @method
    Save sketch as (another place)
  @return {void}
  ###
  _saveSketchAs: ->
    return unless @_lock()
    newDirEntry = null
    editors = null
    new Function.Sequence(
      (seq) =>
        @window.chrome.fileSystem.chooseEntry({type: "openDirectory"}, (dirEntry) =>
          unless dirEntry
            # cancelled by user
            @window.chrome.runtime.lastError
            @_notify("info", Rubic.I18n("Cancelled"))
            return seq.abort()
          newDirEntry = dirEntry
          return seq.next()
        ) # @window.chrome.fileSystem.chooseEntry
      (seq) =>
        Rubic.FileUtil.readEntries(
          newDirEntry
          (entries) =>
            return seq.next() if entries.length == 0
            @_confirmOverwriteDirectory((overwrite) ->
              return seq.next(overwrite)
            )
          =>
            @_notify("danger", "#{Rubic.I18n("CannotReadDirectoryXc")}#{dirEntry.name}")
            return seq.abort()
        ) # Rubic.FileUtil.readEntries
      (seq) =>
        @sketch.saveAs(newDirEntry, (result) =>
          unless result
            @_notify("danger", "#{Rubic.I18n("FailedToSaveSketch")}")
            return seq.abort()
          return seq.next()
        )
      (seq) =>
        editors or= @_editors
        return seq.next() unless editors.length > 0
        editor = editors.shift()
        editor.save((result) =>
          unless result
            @_notify("danger", "#{Rubic.I18n("CannotSaveXc")}#{editor.name}")
            return seq.abort()
          return seq.redo()
        )
    ).final(
      (seq) =>
        if seq.finished
          @_notify("success", Rubic.I18n("TheSketchHasBeenSavedXp"))
        @_unlock()
    ).start()
    return

