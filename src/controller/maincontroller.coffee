# Pre dependencies
WindowController = require("controller/windowcontroller")

###*
@class MainController
  Controller for main view (Controller, Singleton)
@extends Controller
###
class MainController extends WindowController
  instance = null

  #--------------------------------------------------------------------------------
  # Public properties
  #

  ###*
  @static
  @property {MainController}
    The instance of this class
  @readonly
  ###
  @classProperty("instance", get: ->
    return instance or= new MainController(window)
  )

  #--------------------------------------------------------------------------------
  # Private variables / constants
  #

  SCAN_TIMEOUT = 2000
  PLACES = ["local", "googledrive", "dropbox", "onedrive"]
  tabSet = null
  tabNextId = 1

  #--------------------------------------------------------------------------------
  # Protected methods
  #

  ###*
  @protected
  @inheritdoc Controller#onActivated
  ###
  onActivated: ->
    super
    @$(".when-main > .editor-body").hide()
    @$("body").addClass("controller-main")
    @$(".sketch-new").click(=> @_newSketch())
    @$(".open-latest").click(=> @_openSketch())
    for p in PLACES
      do (p) => @$(".open-#{p}").click(=> @_openSketch(p))
    noBoard = !(App.sketch?.board)
    @$(".sketch-build").click(=> @_buildSketch()).prop("disabled", noBoard)
    @$(".sketch-run").click(=> @_runSketch()).prop("disabled", noBoard).next().prop("disabled", noBoard)
    tabSet or= @$("#editor-tabs").scrollTabs({
      left_arrow_size: 18
      right_arrow_size: 18
      click_callback: (=> f = @_tabClick.bind(@); (ev) -> f(this, ev))()
    })
    App.log.detail({"MainController#tabSet": tabSet})
    @$(".board-scan").click(=> @_refreshBoardConnections()) unless noBoard
    @$(".board-name").prop("disabled", true)
    @$(".board-list").prop("disabled", true)
    Promise.resolve(
    ).then(=>
      return Preferences.get("catalog_editor")
    ).then((values) =>
      @$("#cateditor-link")[if values.catalog_editor then "show" else "hide"]()
    )
    Promise.resolve(
    ).then(=>
      return @_newSketch() unless App.sketch?
    ).then(=>
      return @_activeEditor?.activate()
    ).then(=>
      el = @$(".board-name")
      tt = []
      board = App.sketch?.board
      unless board?
        el.text("")
        return
      el.prop("disabled", false)
      @$(".board-list").prop("disabled", false)
      v = board?.friendlyName
      el.text(v)
      tt.push("#{I18n.getMessage("Board")}: #{v}") if v?
      return Promise.resolve(
      ).then(=>
        return board?.loadFirmware()
      ).then((f) =>
        v = f?.friendlyName
        tt.push("#{I18n.getMessage("Firmware")}: #{v}") if v?
        return board?.loadFirmRevision()
      ).then((r) =>
        v = r?.friendlyName
        tt.push("#{I18n.getMessage("Version")}: #{v}") if v?
        el[0].title = tt.join("\n")
      ) # return Promise.resolve().then()...
    ) # Promise.resolve().then()...
    return

  ###*
  @protected
  @inheritdoc Controller#onDeactivated
  ###
  onDeactivated: ->
    @$("body").removeClass("controller-main")
    @$(".sketch-new").unbind("click")
    @$(".open-latest").unbind("click")
    @$(".open-#{p}").unbind("click") for p in PLACES
    @$(".sketch-run").unbind("click")
    @$(".board-scan").unbind("click")
    super
    return

  #--------------------------------------------------------------------------------
  # Private methods
  #

  ###*
  @private
  @method constructor
    Constructor of MainController class
  @param {Window} window
    window object
  ###
  constructor: (window) ->
    super(window)
    @_editors = {}
    @_activeEditor = null
    return

  ###*
  @private
  @method
    Refresh board connection list
  @return {Promise}
    Promise object
  ###
  _refreshBoardConnections: ->
    (tmpl = @$("#board-list-tmpl")).nextAll().remove()
    tmpl.find(".placeholder").eq(0).text(I18n.getMessage("Scanning"))
    return Promise.resolve(
    ).then(=>
      return App.sketch.board.enumerate().timeout(SCAN_TIMEOUT)
    ).then((boards) =>
      return I18n.rejectPromise("No_board") unless boards?.length > 0
      tmpl.hide()
      for b in boards
        li = tmpl.clone().show()
        li[0].id = ""
        ph = li.find(".placeholder")
        ph.eq(0).text(b.friendlyName)
        ph.eq(1).text(b.path or "")
        li.appendTo(tmpl.parent())
        do (b) =>
          li.click(=>
          )
    ).catch((error) =>
      tmpl.text(error).show()
    ) # return Promise.resolve().then()...

  ###*
  @private
  @method
    Set sketch
  @param {Sketch/null} sketch
    Sketch instance
  @return {undefined}
  ###
  _setSketch: (sketch) ->
    App.sketch = sketch
    sketch?.addEventListener("change", (@_sketchChangeListener or= @_sketchChange.bind(this)))
    return

  ###*
  @private
  @method
    Open new sketch
  @return {Promise}
    Promise object
  ###
  _newSketch: ->
    return Promise.resolve(
    ).then(=>
      return @_closeSketch()
    ).then(=>
      return Sketch.createNew()
    ).then((sketch) =>
      @_setSketch(sketch)
      @_addEditor(new SketchEditor(@$, sketch), true)
      for item in sketch.items
        ec = Editor.findEditor(item) if item.path != ""
        @_addEditor(new ec(@$, sketch, item)) if ec?
      return
    ) # return Promise.resolve().then()...

  ###*
  @private
  @method
    Close current sketch
  @param {boolean} dryrun
    Do not close sketch actually
  @param {boolean} force
    Close sketch without confirmation
  @return {Promise}
    Promise object
  ###
  _closeSketch: (dryrun, force) ->
    return Promise.resolve(
    ).then(=>
      return "ok" unless App.sketch?.modified
      return "ok" if force
      return global.bootbox.dialog_p({
        title: I18n.getMessage("Current_sketch_has_been_modified")
        message: I18n.getMessage("Are_you_sure_to_discard_modifications")
        closeButton: false
        buttons: {
          ok: {
            label: I18n.getMessage("Yes_discard_them")
            className: "btn-danger"
          }
          cancel: {
            label: I18n.getMessage("No_cancel_the_operation")
            className: "btn-success"
          }
        }
      })
    ).then((result) =>
      return Promise.reject(Error("Cancelled")) unless result == "ok"
      return if dryrun
      for e in @_editors
        try
          e.deactivate()
          e.close()
        catch e
          null
      @_editors = []
      @$("#editor-tabs").empty()
      @_setSketch(null)
    ) # return Promise.resolve().then()...

  ###*
  @private
  @method
    Open sketch
  @return {Promise}
    Promise object
  ###
  _openSketch: (place) ->
    key = "default_place"
    return Promise.resolve(
    ).then(=>
      return {"#{key}": place} if place? and place != "latest"
      return Preferences.get({"#{key}": "local"})
    ).then((value) =>
      place = value[key]
      return @_closeSketch(true)
    ).then(=>
      switch(place)
        when "local"
          return AsyncFs.chooseDirectory().catch(=> return)
      return Promise.reject(Error("Unsupported place: `#{place}'"))
    ).then((fs) =>
      return unless fs?
      return Sketch.open(fs).then((sketch) =>
        @_setSketch(sketch)
        return  # Last PromiseValue
      ).catch((error) =>
        return global.bootbox.alert_p({
          title: I18n.getMessage("Failed_to_open_sketch")
          message: error.toString()
        })
      )
    ) # return Promise.resolve().then()...

  ###*
  @private
  @method
    Save sketch (overwrite)
  @return {Promise}
    Promise object
  ###
  _saveSketch: ->
    return Promise.reject(Error("No sketch to save")) unless (sketch = App.sketch)?
    spin = @modalSpin().text(I18n.getMessage("Saving_sketch")).show()
    return sketch.save().finally(=>
      spin.hide()
    )

  ###*
  @private
  @method
    Build sketch
  @param {boolean/MouseEvent/KeyboardEvent} [force]
    Force all build (If event is specified, judged by SHIFT key)
  @return {Promise}
    Promise object
  ###
  _buildSketch: (force) ->
    force = force.shiftKey if typeof(force) == "object"
    force = !!force
    return Promise.reject(Error("No sketch to build")) unless (sketch = App.sketch)?
    return Promise.reject(Error("No board")) unless (board = sketch.board)?
    return Promise.reject(Error("No engine")) unless (engine = board?.engine)?
    return Promise.resolve(
    ).then(=>
      return @_saveSketch()
    ).then(=>
      spin = @modalSpin()
      return sketch.items.reduce(
        (promise, item) =>
          spin.text(I18n.getMessage("Building_1", item.path)).show()
          return promise.then(=> return engine.build(sketch, item))
        Promise.resolve()
      ).finally(=>
        spin.hide()
      )
    ) # return Promise.resolve().then()...

  ###*
  @private
  @method
    Run sketch
  @param {boolean/MouseEvent/KeyboardEvent} [force]
    Force all build (If event is specified, judged by SHIFT key)
  @return {Promise}
    Promise object
  ###
  _runSketch: (force) ->
    force = force.shiftKey if typeof(force) == "object"
    force = !!force
    return Promise.reject(Error("No sketch to run")) unless (sketch = App.sketch)?
    return Promise.reject(Error("No board")) unless (board = sketch.board)?
    items = (i for i in sketch.items when i.transfered)
    return Promise.resolve(
    ).then(=>
      return @_buildSketch(force)
    ).then(=>
      spin = @modalSpin()
      cnt = 0
      max = items.length
      return items.reduce(
        (promise, item) =>
          spin.text("#{I18n.getMessage("Transferring_1", item.path)} (#{++cnt}/#{max})").show()
          return promise.then(=> return board.transfer(sketch, item))
        Promise.resolve()
      ).finally(=>
        spin.hide()
      )
    ) # return Promise.resolve().then()...

  ###*
  @private
  @method
    Add an editor tab
  @return {undefined}
  ###
  _addEditor: (editor, activate = false) ->
    id = editor.uniqueId
    unless @_editors[id]?
      @_editors[id] = editor
      tabSet.addTab("""
      <li id="#{id}">#{editor.title}</li>
      """)
    if activate and @_activeEditor != editor
      @_activeEditor?.deactivate()
      (@_activeEditor = editor).activate()
      @$("##{editor.uniqueId}").click()

    return

  ###*
  @private
  @method
    Tab click callback
  @param {DOMElement} element
    Element
  @param {Event} event
    Event
  @return {undefined}
  ###
  _tabClick: (element, event) ->
    editor = @_editors[element.id]
    return unless editor?
    return if editor == @_activeEditor
    @_activeEditor?.deactivate()
    (@_activeEditor = editor).activate()
    return

  ###*
  @private
  @method
    Sketch change handler
  ###
  _sketchChange: ->
    return

module.exports = MainController

# Post dependencies
I18n = require("util/i18n")
Preferences = require("app/preferences")
App = require("app/app")
Sketch = require("sketch/sketch")
AsyncFs = require("filesystem/asyncfs")
SketchEditor = require("editor/sketcheditor")
Editor = require("editor/editor")
