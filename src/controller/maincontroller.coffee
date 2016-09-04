"use strict"
# Pre dependencies
WindowController = require("controller/windowcontroller")

###*
@class MainController
  Controller for main view (Controller, Singleton)
@extends WindowController
###
module.exports = class MainController extends WindowController
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
  SCAN_PERIOD_MS = 1000
  PLACES = ["local", "googledrive", "dropbox", "onedrive"]
  MIN_SAVE_SPIN = 400

  firstActivation = true  # Flag for first activation
  tabSet = null           # jquery-scrollTabs instance for editor tabs
  nextEditorId = 1        # Next editor ID

  #--------------------------------------------------------------------------------
  # Protected methods
  #

  ###*
  @protected
  @inheritdoc Controller#activate
  ###
  activate: ->
    $ = @$
    return super(
    ).then(=>
      # Setup jquery-scrollTabs (only once)
      return unless firstActivation
      tabSet or= $("#editor-tabs").scrollTabs({
        left_arrow_size: 18
        right_arrow_size: 18
      })
      App.log("MainController.tabSet: %o", tabSet)
      return
    ).then(=>
      # Setup other HTML elements (only once)
      return unless firstActivation
      $(".sketch-new")          .click(@_newSketch.bind(this))
      $(".sketch-open-latest")  .click(@_openSketch.bind(this, null))
      $(".sketch-open-local")   .click(@_openSketch.bind(this, "local"))
      $(".sketch-save-over")    .click(@_saveSketch.bind(this, null))
      $(".sketch-saveas-local") .click(@_saveSketch.bind(this, "local"))
      $(".sketch-close")        .click(@_closeSketch.bind(this, false, false))
      $(".sketch-build")        .click(@_buildSketch.bind(this))
      $(".sketch-run")          .click(@_runSketch.bind(this))
      $(".sketch-stop").hide()  .click(@_stopSketch.bind(this))
      $(".board-list") .parent().on("show.bs.dropdown", (event) =>
        # FIXME
        $("#board-list-tmpl").hide()
      ).on("hidden.bs.dropdown", (event) =>
        null
      )
      $(".device-list").parent().on("show.bs.dropdown", (event) =>
        @_popupDeviceList(true)
      ).on("hidden.bs.dropdown", (event) =>
        @_popupDeviceList(false)
      )
      $("#device-list-searching > a").click((event) =>
        $(event.currentTarget).blur()
        event.stopPropagation()
        @_updateDeviceList()
      )
      $("#device-list-hide > a").click((event) =>
        event.stopPropagation()
        $(event.currentTarget).parents("ul").eq(0).removeClass("device-showall")
      )
      $("#device-list-showall > a").click((event) =>
        event.stopPropagation()
        $(event.currentTarget).parents("ul").eq(0).addClass("device-showall")
      )
      $("#device-list-disconnect > a").click((event) =>
        @_board?.disconnect()
      )
    ).then(=>
      return unless firstActivation
      return @_updateElementsForSketch()
    ).then(=>
      return unless firstActivation
      return @_updateElementsForBoard()
    ).then(=>
      firstActivation = false
    ).then(=>
      $("body").addClass("controller-main")
    ).then(=>
      return @_regenerate()
      #   ).then(=>
      #     return @_newSketch() unless App.sketch?
      #   ).then(=>
      #     return unless (sketch = App.sketch)?
      #     return unless sketch.items.length == 0
      #     return sketch.board?.loadFirmware().catch(=>
      #       return
      #     )
      #   ).then((firmware) =>
      #     fileHandler = null
      #     for h in (firmware?.fileHandlers or [])
      #       if h.suffix?
      #         fileHandler = h
      #         break
      #     return unless fileHandler?
      #     spin = @modalSpin().text(I18n.getMessage("Generating_source_codes")).show()
      #     return Promise.all([Promise.delay(1000), Promise.resolve(
      #     ).then(=>
      #       main = "main.#{fileHandler.suffix}"
      #       item = new SketchItem({path: main, transfer: false})
      #       sketch.addItem(item)
      #       sketch.setupItems()
      #       editorClass = Editor.findEditor(item)
      #       @_addEditor(new editorClass(@$, sketch, item)) if editorClass?
      #       return
      #     ).catch((error) =>
      #       App.error(error)
      #     )]).finally(
      #       spin.hide()
      #     ) # return Promise.all().finally()
      #   ).then(=>
      #     return @_activeEditor?.activate()
    ) # return super().then()...

  ###*
  @protected
  @inheritdoc Controller#deactivate
  ###
  deactivate: ->
    $ = @$
    $("body").removeClass("controller-main")
    return super()

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
    @_sketch = App.sketch
    @_board = @_sketch?.board
    @_editors = []
    @_activeEditor = null
    @_running = null
    return

  ###*
  @private
  @method
    Update DOM elements for sketch
  @return {Promise}
    Promise object
  ###
  _updateElementsForSketch: ->
    $ = @$
    noSketch = !@_sketch?
    $("body").toggleClass("no-sketch", noSketch)
    $(".when-main > .editor-body").hide()
    if noSketch
      # Welcome page
      tabSet.clearTabs()
      tabSet.addTab("<li id=\"editor-welcome\">#{I18n.getMessage("Welcome")}</li>")
      $("#editor-welcome").click()
      $("#welcome-page").show()
      tmpl = $("#recent-sketch-tmpl").hide()
      $("#clear-recent-sketch").hide()
    else
      # Restore tabs
    return Promise.resolve()

  ###*
  @private
  @method
    Update DOM elements for board
  @return {Promise}
    Promise object
  ###
  _updateElementsForBoard: ->
    $ = @$
    noBoard = !@_board?
    $(".sketch-build").prop("disabled", noBoard)
    $(".device-list").prop("disabled", noBoard)
    if noBoard
      $(".sketch-run").prop("disabled", true).next().prop("disabled", true)
      $(".board-info").prop("disabled", true)
    else
      $("a.sketch-debug").parent().toggleClass("disabled", !@_board.debuggable)
    elem = $("#board-selected")
    elem.text(@_board?.friendlyName or "")
    elem[0].title = ""
    return Promise.resolve() if noBoard
    return Promise.resolve(
    ).then(=>
      return @_board.loadFirmware()
    ).then((firmware) =>
      elem[0].title += "#{I18n.getMessage("Firmware")} : #{firmware.friendlyName}\n"
      return @_board.loadFirmRevision()
    ).then((firmRevision) =>
      elem[0].title += "#{I18n.getMessage("Revision")} : #{firmRevision.friendlyName}\n"
    ) # return Promise.resolve()

  ###*
  @private
  @method
    Regenerate skeleton code
  ###
  _regenerate: ->
    return unless @_needRegenerate
    @_needRegenerate = false
    return unless @_sketch?
    return @_sketch.generateSkeleton()

  ###*
  @private
  @method
    Set sketch
  @param {Sketch/null} sketch
    Sketch instance
  @return {undefined}
  ###
  _setSketch: (sketch) ->
    App.sketch?.removeEventListener("boardchange", this)
    @_board?.disconnect() if @_board?.connected
    @_sketch = App.sketch = sketch
    @_sketch?.addEventListener("boardchange", this)
    @_updateElementsForSketch()
    @_board = @_sketch?.board
    @_updateElementsForBoard()
    @_needRegenerate = false
    @_editors = []
    tabSet.clearTabs()
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
      # for item in sketch.items
      #   ec = Editor.findEditor(item) if item.path != ""
      #   @_addEditor(new ec(@$, sketch, item)) if ec?
      return
    ) # return Promise.resolve().then()...

  ###*
  @private
  @method
    Close current sketch
  @param {boolean} [dryrun=false]
    Do not close sketch actually
  @param {boolean} [force=false]
    Close sketch without confirmation
  @return {Promise}
    Promise object
  ###
  _closeSketch: (dryrun = false, force = false) ->
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
      })  # return global.bootbox.dialog_p()
    ).then((result) =>
      return Promise.reject(Error("Cancelled")) unless result == "ok"
      return if dryrun
      return @_editors.reduce(
        (promise, editor) =>
          return promise.then(=>
            return editor.deactivate()
          ).then(=>
            return editor.close()
          ).catch(=>
            App.warn("Cannot deactivate/close editor: %o", editor)
          )
        Promise.resolve()
      ).then(=>
        return if dryrun
        @_editors = []
        @$("#editor-tabs").empty()
        @_setSketch(null)
        return
      ) # return @_editors.reduce().then()
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
    sketch = App.sketch
    return Promise.reject(Error("No sketch to save")) unless sketch?
    spin = @modalSpin().text(I18n.getMessage("Saving_sketch")).show()
    return Promise.resolve(
    ).then(=>
      return sketch.setupItems()
    ).then(=>
      return sketch.save()
    ).finally(=>
      spin.hide(MIN_SAVE_SPIN)
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
    sketch = App.sketch
    return Promise.reject(Error("No sketch to build")) unless sketch?
    board = sketch.board
    return Promise.reject(Error("No board")) unless board?
    return Promise.resolve(
    ).then(=>
      return sketch.setupItems()
    ).then(=>
      return @_saveSketch()
    ).then(=>
      spin = @modalSpin()
      return sketch.build(
        force
        (path, progress, error) =>
          return App.popupError(
            I18n.getMessage("Failed_to_build_1", path)
            I18n.getMessage("Build_failed")
          ) if error?
          return spin.text(
            "#{I18n.getMessage("Building_1", path)} (#{Math.round(progress)}%)"
          )
      ).finally(=>
        spin.hide(500)
      ) # return sketch.build()...
    ) # return Promise.resolve().then()...

  ###
  @private
  @method
    Transfer sketch
  @param {boolean/MouseEvent/KeyboardEvent} [force]
    Force all build (If event is specified, judged by SHIFT key)
  @return {Promise}
    Promise object
  ###
  _transferSketch: (force) ->
    force = force.shiftKey if typeof(force) == "object"
    force = !!force
    sketch = App.sketch
    return Promise.reject(Error("No sketch to build")) unless sketch?
    board = sketch.board
    return Promise.reject(Error("No board")) unless board?
    return Promise.resolve(
    ).then(=>
      spin = @modalSpin()
      return sketch.transfer(
        force
        (path, progress, error) =>
          return App.popupError(
            I18n.getMessage("Failed_to_transfer_1", path)
            I18n.getMessage("Transfer_failed")
          ) if error?
          return spin.text(
            "#{I18n.getMessage("Transferring_1", path)} (#{Math.round(progress)}%)"
          )
      ).finally(=>
        spin.hide()
      ) # return sketch.transfer()...
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
    $ = @$
    sketch = App.sketch
    return Promise.reject(Error("No sketch to run")) unless sketch?
    board = sketch.board
    return Promise.reject(Error("No board")) unless board?
    items = (i for i in sketch.items when i.transfered)
    return Promise.resolve(
    ).then(=>
      return @_buildSketch(force)
    ).then(=>
      return @_transferSketch(force)
    ).then(=>
      unless sketch.bootItem?
        App.popupError(I18n.getMessage("No_program_to_boot"))
        return Promise.reject(Error("No program to boot"))
      @_running = Promise.resolve(
      ).then(=>
        $(".sketch-run").hide()
        $(".sketch-stop").show()
      ).then(=>
        return board.startSketch()
      ).then(=>
      ).finally(=>
        $(".sketch-stop").hide()
        $(".sketch-run").show()
        @_running = null
      )
      return  # Do not wait until sketch finish
    ) # return Promise.resolve().then()...

  ###*
  @private
  @method
    Stop sketch
  @return {Promise}
    Promise object
  ###
  _stopSketch: ->
    sketch = App.sketch
    return Promise.reject(Error("No sketch")) unless sketch?
    board = sketch.board
    return Promise.reject(Error("No board")) unless board?
    return Promise.reject(Error("Already stopped")) unless @_running
    spin = @modalSpin()
    return Promise.resolve(
    ).then(=>
      return board.stopSketch()
    ).finally(=>
      return @_running
    ).finally(=>
      spin.hide()
    )

  ###*
  @private
  @method
    Popup board device list
  @param {boolean} state
    true:shown, false:hidden
  @return {undefined}
  ###
  _popupDeviceList: (state) ->
    $ = @$
    tmpl = $("#device-list-tmpl").hide()
    unless state
      id = @_deviceListUpdateTimer
      window.clearTimeout(id) if id?
      @_deviceListUpdateTimer = null
      return
    $("#device-list-searching").toggle(@_board?)
    $("#device-list-noboard").toggle(!@_board?)
    if @_board?
      tmpl.siblings().filter(".device-list-item").remove()
      @_updateDeviceList()
    return

  ###*
  @private
  @method
    Update board device list
  ###
  _updateDeviceList: ->
    $ = @$
    board = App.sketch?.board
    return Promise.reject(Error("No board")) unless board?
    id = @_deviceListUpdateTimer
    window.clearTimeout(id) if id?
    @_deviceListUpdateTimer = null
    tmpl = $("#device-list-tmpl").hide()
    return Promise.resolve(
    ).then(=>
      return board.enumerate()
    ).then((boards) =>
      boards.sort((a, b) =>
        return -1 if a < b
        return +1 if a > b
        return 0
      )
      elem = (prev = tmpl).next()
      hasHidden = false
      for item in boards
        path = elem.children("a")[0]?.dataset.path
        hasHidden = true if item.hidden
        if !path or path > item.path
          # New item
          elem = prev.after(tmpl.clone()).next()
          elem[0].id = ""
          a = elem.children("a")
          a[0].dataset.path = item.path
          title = ""
          title += sprintf("Vendor ID : %04X\n", item.vendorId) if item.vendorId?
          title += sprintf("Product ID : %04X\n", item.productId) if item.productId?
          a[0].title = title
          ph = a.find(".placeholder")
          ph.eq(0).text(item.friendlyName)
          ph.eq(1).text(item.path)
          elem.addClass("device-list-hidden") if item.hidden
          elem.show()
          elem = (prev = elem).next()
        else if path < item.path
          # Removed item
          elem = (prev = elem).remove().next()
        else
          # No change
          elem = (prev = elem).next()
      # Removed item
      (elem = elem.remove().next()) while elem.hasClass("device-list-item")
      # Has hidden items?
      tmpl.parent().toggleClass("device-has-hidden", hasHidden)
      # Bind event listener
      $(".device-list-item > a").unbind("click").click(@_deviceSelect.bind(this))
    ).then(=>
      @_deviceListUpdateTimer = window.setTimeout(
        @_updateDeviceList.bind(this)
        SCAN_PERIOD_MS
      )
      return
    )

  ###*
  @private
  @method
    Device selection
  @param {Event} event
    DOM event
  ###
  _deviceSelect: (event) =>
    path = event.currentTarget.dataset.path
    return unless path?
    @_boardPath = path
    return unless @_board?
    Promise.resolve(
    ).then(=>
      return unless @_board.connected
      return @_board.disconnect()
    ).then(=>
      @_board.connect(@_boardPath)
    )
    return

  ###*
  @method
    Event handler
  @param {Object} event
    Event object
  @return {undefined}
  ###
  handleEvent: (event) ->
    $ = @$
    switch event.type
      when "boardchange"
        @_board?.disconnect() if @_board?.connected
        @_board = @_sketch?.board
        App.info("Board changed (%o)", @_board)
        @_board?.addEventListener("connect", this)
        @_board?.addEventListener("disconnect", this)
        @_updateElementsForBoard()
        @_needRegenerate = true
        @_regenerate()
      when "connect"
        App.popupInfo(I18n.getMessage("Connected_to_board_at_1", @_boardPath))
        $("body").addClass("board-connected")
        $("#device-selected").text(@_boardPath)
        $(".sketch-run").prop("disabled", false).next().prop("disabled", false)
        $(".board-info").prop("disabled", false)
      when "disconnect"
        App.popupWarning(I18n.getMessage("Disconnected_from_board_at_1", @_boardPath))
        $("body").removeClass("board-connected")
        $("#device-selected").text("")
        $(".sketch-run").prop("disabled", true).next().prop("disabled", true)
        $(".board-info").prop("disabled", true)
        @_boardPath = null
        return unless @_board?
        @_board.removeEventListener("connect", this)
        @_board.removeEventListener("disconnect", this)
      when "changetitle"
        editor = event.target
        $("li##{editor.id}").text(editor.title)
    return

  ###*
  @private
  @method
    Add an editor tab
  @return {undefined}
  ###
  _addEditor: (editor, activate = false) ->
    unless @_editors.includes(editor)
      editor.id = "editor-id-#{nextEditorId++}"
      tabSet.addTab("<li class=\"editor-tab\" id=\"#{editor.id}\"></li>")
      $("li##{editor.id}").text(editor.title).click(
        @_selectEditor.bind(this, editor)
      )
      editor.addEventListener("changetitle", this)
    App.log("New editor (%o)", editor)
    $("li##{editor.id}").click() if activate
    return

  ###*
  @private
  @method
    Select an editor tab
  @param {Editor} editor
    Selected editor
  @return {undefined}
  ###
  _selectEditor: (editor) ->
    return if editor == @_activeEditor
    @_activeEditor?.deactivate()
    (@_activeEditor = editor).activate()
    return

# Post dependencies
I18n = require("util/i18n")
Preferences = require("app/preferences")
App = require("app/app")
Sketch = require("sketch/sketch")
AsyncFs = require("filesystem/asyncfs")
SketchItem = require("sketch/sketchitem")
SketchEditor = require("editor/sketcheditor")
Editor = require("editor/editor")
sprintf = require("util/sprintf")
