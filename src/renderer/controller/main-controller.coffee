"use strict"
require("../../util/primitive")
WindowController = require("./window-controller")
once = require("once")
i18n = require("i18n")

###*
Controller for main view (Controller, Singleton, Renderer-process)

@class MainController
@extends WindowController
###
module.exports =
class MainController extends WindowController

  constructor: ->
    super
    @_editors = []
    return

  ###*
  The singleton instance of this class

  @property {MainController} instance
    The instance of this class
  @readOnly
  ###
  @staticProperty("instance", get: ->
    return @_instance or= new MainController()
  )

  @_instance: null

  #--------------------------------------------------------------------------------
  # Private variables / constants
  #

  SCAN_TIMEOUT: 2000
  SCAN_PERIOD_MS: 1000
  CONNECT_TIMEOUT: 5000
  BOARD_INFO_TIMEOUT: 5000
  CATALOG_TIMEOUT: 10000
  KEY_RECENT_SKETCHES_MAX: "recent_sketches.max"
  DEF_RECENT_SKETCHES_MAX: 10
  KEY_RECENT_SKETCHES_ITEMS: "recent_sketches.items"
  KEY_DEFPLACE: "default_place"
  PLACES: ["local", "googledrive", "dropbox", "onedrive"]
  MIN_SAVE_SPIN: 400
  TAB_SELECTOR: "li.editor-tab"

  _firstActivation: true  # Flag for first activation
  _tabSet: null           # jquery-scrollTabs instance for editor tabs
  _aceEditor: null        # Ace editor for output window

  #--------------------------------------------------------------------------------
  # Protected methods
  #

  ###*
  @protected
  @inheritdoc Controller#activate
  ###
  activate: ->
    return super(
    ).then(=>
      return @_setupMain()
    ).then(=>
      $("body").addClass("controller-main")
    ).then(=>
      #return @_regenerate()
    ) # return super().then()...

  ###*
  Setup HTML contents for the first time

  @private
  @method _setupMain
  @return {Promise|undefined}
  ###
  _setupMain: once ->
    return Promise.resolve(
    ).then(=>
      # Setup jquery-scrollTabs
      @_tabSet = $("#editor-tabs").scrollTabs(
        left_arrow_size: 18
        right_arrow_size: 18
        click_callback: (event) =>
          index = $(event.currentTarget).prevAll(@TAB_SELECTOR).length
          editor = @_editors[index]
          return unless editor?
          if $(event.target).hasClass("editor-close-button")
            Promise.resolve(
            ).then(=>
              return "yes" unless editor.modified
              return App.safeConfirm_yes_no(
                rawTitle: i18n.__("File_1_has_been_modified", editor.sketchItem?.path)
                message: "{Are_you_sure_to_discard_modifications}"
                yes: "{Yes_discard_them}"
                no: "{No_cancel_the_operation}"
              )
            ).then((result) =>
              return unless result == "yes"
              @removeEditor(editor) if editor.closable
              return
            )
          else
            @_activateEditor(editor)
          return
      )

      # Setup Ace editor for output window (only once)
      ace.Range = ace.require("ace/range").Range
      @_aceEditor = ace.edit($(".editor-bottom")[0])
      @_aceEditor.$blockScrolling = Infinity
      @_aceEditor.renderer.setShowGutter(false)
      @_aceEditor.setTheme("ace/theme/twilight")
      @_aceEditor.setShowPrintMargin(false)
      @_aceEditor.setReadOnly(true)

      # Setup other HTML elements (only once)
      $(".sketch-new")          .click(@_newSketch.bind(this))
      $(".sketch-open-latest")  .click(@_openSketch.bind(this, null, null))
      $(".sketch-open-local")   .click(@_openSketch.bind(this, "local", null))
      $(".sketch-save-overwrite").click(@_saveSketch.bind(this, null))
      $(".sketch-save-local")   .click(@_saveSketch.bind(this, "local"))
      $(".sketch-close")        .click(@_closeSketch.bind(this, false, false))
      $(".sketch-build")        .click(@_buildSketch.bind(this))
      $(".sketch-run")          .click(@_runSketch.bind(this))
      $(".sketch-stop").hide()  .click(@_stopSketch.bind(this))
      $(".clear-recent-sketch") .click(@_clearRecentSketch.bind(this))
      $(".board-list").parent().on("show.bs.dropdown", (event) =>
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
      $(".board-info").click((event) =>
        spin = @modalSpin().text(i18n.__("Reading_board_info")).show()
        return Promise.resolve(
        ).then(=>
          return @_board?.getBoardInfo()
        ).timeout(
          @BOARD_INFO_TIMEOUT
        ).finally(=>
          return spin.hide(500)
        ).then((info) =>
          table = $("#template-table").children().clone()
          $("#template-tr-th11").children().clone()
            .appendTo(table.find("thead")).find("th")
            .eq(0).text(i18n.__("Board_info")).end()
            .eq(1).text("#{@_board.friendlyName} [#{@_board.path}]").end()
          for k, v of info
            $("#template-tr-td11").children().clone()
              .appendTo(table.find("tbody")).find("td")
              .eq(0).text(i18n.__(k)).end()
              .eq(1).text(v).end()
          return global.bootbox.alert_p({
            # title: i18n.__("Board_info")
            message: table
          })
        ).catch((error) =>
          App.popupError(error?.message or error)
        ) # return Promise.resolve().then()...
      )
      return
    ).then(=>
      return @_updateElementsForSketch()
    ).then(=>
      return @_updateElementsForBoard()
    ).then(=>
      @bindKey("mod+o", ".sketch-open-latest")
      @bindKey("mod+b", ".sketch-build")
      @bindKey("mod+r", ".sketch-run")
      @bindKey("mod+s", ".sketch-save-overwrite")
    ) # return Promise.resolve().then()...

  ###*
  @protected
  @inheritdoc Controller#deactivate
  ###
  deactivate: ->
    $("body").removeClass("controller-main")
    return super()

  ###*
  @method
    Add an editor tab
  @param {Editor} editor
    Editor instance
  @param {number} [position=null]
    Tab position
  @param {boolean} [activate=false]
    Activate editor after adding
  @return {Promise}
    Promise object
  ###
  addEditor: (editor, position = null, activate = false) ->
    exists = @_editors.indexOf(editor)
    if exists >= 0
      position = exists
    else
      position ?= @_editors.length
      @_editors.splice(position, 0, editor)
      s = @TAB_SELECTOR.split(".")
      @_tabSet.addTab("""
      <#{s[0]} class="#{s[1]}">
        <span class="editor-modified fa fa-pencil"></span>
        <span class="editor-readonly fa fa-lock"></span>
        <a href="#"></a>
        <span class="editor-close-button glyphicon glyphicon-remove"></span>
      </#{s[0]}>
      """, position)
      tab = $(@_tabSet.domObject).find(@TAB_SELECTOR).eq(position)
      tab.find("a").eq(0).text(editor.title or "")
      tab.find("span.editor-modified").hide() unless editor.modified
      tab.find("span.editor-readonly").hide() if editor.editable
      tab.find("span.editor-close-button").remove() unless editor.closable
      editor.addEventListener("changetitle.editor", this)
      editor.addEventListener("change.editor", this)
      App.log("New editor (%o) at index %d", editor, position)
    $(@_tabSet.domObject).find(@TAB_SELECTOR).eq(position).click() if activate
    return Promise.resolve(true)

  ###*
  @method
    Remove an editor
  @param {Editor} editor
    Editor instance
  @return {Promise}
    Promise object
  ###
  removeEditor: (editor) ->
    position = @_editors.indexOf(editor)
    return Promise.resolve(false) if position < 0
    return Promise.resolve(
    ).then(=>
      return unless editor == @_activeEditor
      return editor.deactivate()
    ).then(=>
      @_activeEditor = null
      return editor.close()
    ).then(=>
      editor.destroy()
      @_editors.splice(position, 1)
      $(@_tabSet.domObject).find(@TAB_SELECTOR).eq(position).remove()
      position = Math.min(position, @_editors.length - 1)
      $(@_tabSet.domObject).find(@TAB_SELECTOR).eq(position).click() if position >= 0
      return true # Last PromiseValue
    ) # return Promise.resolve().then()...

  ###*
  @method
    Clear output window
  @return {undefined}
  ###
  clearOutput: ->
    session = Ace.createEditSession("", "ace/mode/text")
    session.setUseWrapMode(true)
    @_aceEditor.setSession(session)
    return

  ###*
  @method
    Print text to output window
  @param {string} text
    Text to print
  @param {string} [marker=null]
    Marker class
  @param {boolean} [newline=false]
    Force new line
  @return {undefined}
  ###
  printOutput: (text, marker = null, newline = false) ->
    session = @_aceEditor.getSession()
    range = new Ace.Range
    row = session.getLength() - 1
    range.start = {
      row: row
      column: session.getScreenLastRowColumn(row)
    }
    if newline and range.start.column > 0
      range.start = session.insert(range.start, "\n")
    range.end = session.insert(range.start, text)
    # session.addMarker(range, "marker-#{marker}", "line") if marker?
    @_aceEditor.navigateFileEnd()
    @_aceEditor.scrollToRow(range.end.row)
    return

  ###*
  @method
    Print system message to output window
  @param {string} text
    Text to print
  @param {boolean} [newline=true]
    Add LF to the end of text
  @return {undefined}
  ###
  printSystem: (text, newline = true) ->
    text = "#{text}\n" if newline
    @printOutput(text, "system", newline)
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
  caonstructor: (window) ->
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
    Get tab element
  @param {number/Editor} position
    Tab position / editor instance
  @return {jQuery}
    jQuery object
  ###
  _getTab: (position) ->
    unless typeof(position) == "number"
      position = @_editors.indexOf(position)
    return null if position < 0
    return $(@_tabSet.domObject).find(@TAB_SELECTOR).eq(position)

  ###*
  @private
  @method
    Update DOM elements for sketch
  @return {Promise}
    Promise object
  ###
  _updateElementsForSketch: ->
    noSketch = !@_sketch?
    $("body").toggleClass("no-sketch", noSketch)
    $(".when-main > .editor-body").hide()
    return Promise.resolve() unless noSketch

    # Construct welcome page
    @_tabSet.clearTabs()
    @_tabSet.addTab("<li id=\"editor-welcome\">#{i18n.__("Welcome")}</li>")
    $("#editor-welcome").click()
    tmpl = $("#recent-sketch-tmpl").children()
    container = $("#recent-sketches").empty()
    return @constructor._getRecentSketches(
    ).then((items) =>
      $("#clear-recent-sketch").hide()
      for item in items
        break unless item.friendlyName?
        do (item) =>
          $("#clear-recent-sketch").show()
          (a = tmpl.clone()).appendTo(container)
          a.find(".placeholder")
            .eq(0).text(i18n.__n("Open_sketch_1", item.friendlyName)).end()
            .eq(1).html("""
            #{i18n.__("Stored_location")}: #{
              i18n.__("fsType_#{item.fsType}")
            }&nbsp;&nbsp;/&nbsp;&nbsp;#{
              i18n.__("Last_used_time")}: #{
              new Date(item.lastUsed).toLocaleString()
            }
            """).end()
          a.click((event) =>
            AsyncFs.restorefs(item.retainInfo).then((fs) => @_openSketch(null, fs))
          ).show()
      $("#welcome-page").show()
      return
    ) # return @constructor._getRecentSketches().then()

  ###*
  @private
  @method
    Update DOM elements for board
  @return {Promise}
    Promise object
  ###
  _updateElementsForBoard: ->
    noBoard = !@_board?
    $(".sketch-build").prop("disabled", noBoard)
    $(".device-list").prop("disabled", noBoard)
    if noBoard
      $(".sketch-run,.sketch-stop,.board-info,.board-program")
        .prop("disabled", true)
        .next(".dropdown-toggle").prop("disabled", true)
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
      elem[0].title += "#{i18n.__("Firmware")} : #{firmware.friendlyName}\n"
      return @_board.loadFirmRevision()
    ).then((firmRevision) =>
      elem[0].title += "#{i18n.__("Revision")} : #{firmRevision.friendlyName}\n"
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
    return Promise.resolve(
    ).then(=>
      return @_sketch.generateSkeleton()
    ).then(=>
      item = @_sketch.bootItem
      return unless item?
      while true
        source = item.source
        break unless source?
        item = source

      editor = item.editor
      unless editor?
        editorClass = Editor.findEditor(item)
        unless editorClass?
          App.popupError(i18n.__("Cannot_find_editor"))
          return false
        editor = new editorClass(@$, @_sketch, item)
      @addEditor(editor, null, true)
      return true
    ) # return Promise.resolve()

  ###*
  @private
  @method
    Set sketch
  @param {Sketch/null} sketch
    Sketch instance
  @return {undefined}
  ###
  _setSketch: (sketch) ->

    # Unregister old sketch and board
    App.sketch?.removeEventListener("setboard.sketch", this)
    App.sketch?.removeEventListener("change.sketch", this)
    App.sketch?.removeEventListener("save.sketch", this)
    @_board?.disconnect() if @_board?.connected

    # Register new sketch and board
    @_sketch = App.sketch = sketch
    App.log("Open sketch (%o)", @_sketch)
    @_sketch?.addEventListener("setboard.sketch", this)
    @_sketch?.addEventListener("change.sketch", this)
    @_sketch?.addEventListener("save.sketch", this)
    @clearOutput()
    @_running = null
    $(".sketch-stop").hide()
    $(".sketch-run").closest(".btn-group").show()
    @_editors = []
    @_tabSet.clearTabs()
    @_updateElementsForSketch()
    @_board = @_sketch?.board
    @_board?.addEventListener("connect.board", this)
    @_board?.addEventListener("disconnect.board", this)
    @_updateElementsForBoard()
    @_needRegenerate = false
    return

  ###*
  @private
  @method
    Open new sketch (without updating recent sketch list)
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
      @addEditor(new SketchEditor(@$, sketch), null, true)
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
      sketch = App.sketch
      return "yes" if !(sketch?.modified) and !(sketch?.itemModified)
      return "yes" if force
      return App.safeConfirm_yes_no(
        title: "{Current_sketch_has_been_modified}"
        message: "{Are_you_sure_to_discard_modifications}"
        yes: "{Yes_discard_them}"
        no: "{No_cancel_the_operation}"
      )
    ).then((result) =>
      return Promise.reject(Error("Cancelled")) unless result == "yes"
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
        e?.destroy() for e in @_editors
        @_editors = []
        @$("#editor-tabs").empty()
        @_setSketch(null)
        return
      ) # return @_editors.reduce().then()
    ) # return Promise.resolve().then()...

  ###*
  @private
  @method
    Open sketch (with updating recent sketch list)
  @param {"latest"/"local"} [place="latest"]
    Place to lookup sketches
  @param {AsyncFs} [fs=null]
    Filesystem object to open
  @return {Promise}
    Promise object
  ###
  _openSketch: (place = "latest", fs = null) ->
    return Promise.resolve(
    ).then(=>
      return fs if fs?
      return Promise.resolve(
      ).then(=>
        return {"#{@KEY_DEFPLACE}": place} if place != "latest"
        return global.rubic.settings.get({"#{@KEY_DEFPLACE}": "local"})
      ).then((value) =>
        place = value[@KEY_DEFPLACE]
        return @_closeSketch(true)
      ).then(=>
        switch(place)
          when "local"
            return AsyncFs.chooseDirectory().catch(=> return)
        return Promise.reject(Error("Unsupported place (#{place})"))
      ) # return Promise.resolve().then()...
    ).then((fs) =>
      return unless fs?
      return Sketch.open(fs).then(({sketch, migration}) =>
        return Promise.resolve(
        ).then(=>
          return unless migration?.catalogUpdate
          return BoardCatalog.load(true)
        ).then(=>
          @_setSketch(sketch)
        ).then(=>
          return @_restoreWorkspace()
        ).then(=>
          return @constructor._updateRecentSketch(sketch)
        ).then(=>
          return unless migration?
          App.popupInfo("""
            #{i18n.__("This_sketch_was_migrated_from_1", migration.from)}<br>
            #{i18n.__("Saved_as_new_version_at_next_save")}
          """)
          return unless migration.regenerate
          @_needRegenerate = true
          return @_regenerate()
        ) # return Promise.resolve().then()...
      ).then(=>
        return  # Last PromiseValue
      ).catch((error) =>
        return global.bootbox.alert_p({
          title: i18n.__("Failed_to_open_sketch")
          message: error.toString()
        })
      )
    ) # return Promise.resolve().then()...

  ###*
  @private
  @method
    Save sketch
  @param {"overwrite"/"local"} [place="overwrite"]
  @return {Promise}
    Promise object
  ###
  _saveSketch: (place = "overwrite") ->
    return Promise.reject(Error("No sketch to save")) unless @_sketch?
    spin = @modalSpin().text(i18n.__("Saving_sketch")).show()
    oldFriendlyName = @_sketch.friendlyName?.toString()
    oldFsType = @_sketch.dirFs.fsType
    return Promise.resolve(
    ).then(=>
      return @_sketch.setupItems()
    ).then(=>
      return if place == "overwrite"
      newDirFs = null
      return Promise.resolve(
      ).then(=>
        switch place
          when "local"
            return AsyncFs.chooseDirectory()
        return Promise.reject(Error("Unsupported place (#{place})"))
      ).then((dirFs) =>
        newDirFs = dirFs
        return Sketch.exists(newDirFs)
      ).then((exists) =>
        return "yes" unless exists
        return App.safeConfirm_yes_no(
          title: "{Sketch_overwrite_confirmation}"
          message: "{Are_you_sure_to_overwrite_existing_sketch}"
          yes: "{Yes_overwrite}"
          no: "{No_cancel_the_operation}"
        )
      ).then((confirm) =>
        return Promise.reject(Error("Cancelled by user")) unless confirm == "yes"
        return global.rubic.settings.set({"#{@KEY_DEFPLACE}": place})
      ).then(=>
        return newDirFs
      ).catch((error) =>
        App.popupWarning(i18n.__("Sketch_save_canceled"))
        App.error(error)
        return Promise.reject()
      ) # return Promise.resolve()
    ).then((dirFs) =>
      return @_backupWorkspace().then(=>
        return @_sketch.save(dirFs)
      ).then(=>
        return @constructor._updateRecentSketch(@_sketch, oldFriendlyName, oldFsType)
      )
    ).then(=>
      if @_sketch.dirFs.fsType == AsyncFs.TEMPORARY
        id = "Sketch_was_saved_in_draft"
      else
        id = "Sketch_was_saved"
      App.popupSuccess(i18n.__(id))
      return  # Do not wait until notification closing
    ).finally(=>
      spin.hide(@MIN_SAVE_SPIN)
    ).catch((error) =>
      App.popupError(error) if error?
      return  # Do not wait until notification closing
    ) # return Promise.resolve().then()...

  ###*
  @private
  @method
    Backup workspace
  @return {Promise}
    Promise object
  ###
  _backupWorkspace: ->
    return Promise.resolve(
    ).then(=>
      @_sketch?.workspace = {
        editors: ({
          className: editor.className
          path: editor.sketchItem?.path
          active: (editor == @_activeEditor) or undefined
        } for editor in @_editors)
      }
      return
    ) # return Promise.resolve().then()

  ###*
  @private
  @method
    Restore workspace
  @return {Promise}
    Promise object
  ###
  _restoreWorkspace: ->
    return Promise.resolve(
    ).then(=>
      @_clearEditors()
      workspace = @_sketch?.workspace
      return unless workspace
      for desc in (workspace.editors or [])
        editorClass = Editor.findEditor(desc.className)
        if editorClass?
          path = desc.path
          item = @_sketch.getItem(path) if path?
          @addEditor(new editorClass(@$, @_sketch, item), null, !!desc.active)
      return
    ) # return Promise.resolve().then()

  ###*
  @private
  @method
    Build sketch
  @param {boolean/MouseEvent/KeyboardEvent} [force]
    Force all build (If event is specified, judged by SHIFT key)
  @param {boolean} [keepOutput=false]
    Keep output window
  @return {Promise}
    Promise object
  ###
  _buildSketch: (force, keepOutput = false) ->
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
      @clearOutput() unless keepOutput
      return sketch.build(
        force
        (path, progress, step, error) =>
          msg = i18n.__("Building_1", path)
          switch step
            when Sketch.STEP_START
              @printSystem(msg, false)
            when Sketch.STEP_FINISHED
              @printSystem("#{i18n.__("Succeeded")}\n", false)
            when Sketch.STEP_SKIPPED
              @printSystem("#{i18n.__("Skipped")}\n", false)
            when Sketch.STEP_ABORTED
              @printSystem("#{i18n.__("Failed")}\n", false)
          return App.popupError(
            i18n.__("Failed_to_build_1", path)
            i18n.__("Build_failed")
          ) if error?
          spin.text(
            "#{msg} (#{Math.round(progress)}%)"
          )
          return
      ).then(=>
        msg = i18n.__("Build_succeeded")
        @printSystem(msg)
        # App.popupSuccess(msg)
        return  # Do not wait until notification closing
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
  @param {boolean} [keepOutput=false]
    Keep output window
  @return {Promise}
    Promise object
  ###
  _transferSketch: (force, keepOutput = false) ->
    force = force.shiftKey if typeof(force) == "object"
    force = !!force
    sketch = App.sketch
    return Promise.reject(Error("No sketch to build")) unless sketch?
    board = sketch.board
    return Promise.reject(Error("No board")) unless board?
    return Promise.resolve(
    ).then(=>
      spin = @modalSpin()
      @clearOutput() unless keepOutput
      return sketch.transfer(
        force
        (path, progress, step, error) =>
          msg = i18n.__("Transferring_1", path)
          switch step
            when Sketch.STEP_START
              @printSystem(msg, false)
            when Sketch.STEP_FINISHED
              @printSystem("#{i18n.__("Succeeded")}\n", false)
            when Sketch.STEP_SKIPPED
              @printSystem("#{i18n.__("Skipped")}\n", false)
            when Sketch.STEP_ABORTED
              @printSystem("#{i18n.__("Failed")}\n", false)
          return App.popupError(
            i18n.__("Failed_to_transfer_1", path)
            i18n.__("Transfer_failed")
          ) if error?
          return spin.text(
            "#{msg} (#{Math.round(progress)}%)"
          )
      ).then(=>
        msg = i18n.__("Transfer_succeeded")
        @printSystem(msg)
        # App.popupSuccess(msg)
        return  # Do not wait until notification closing
      ).finally(=>
        spin.hide(500)
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
    sketch = App.sketch
    return Promise.reject(Error("No sketch to run")) unless sketch?
    board = sketch.board
    return Promise.reject(Error("No board")) unless board?
    return Promise.reject(Error("Already running")) if @_running
    items = (i for i in sketch.items when i.transfered)
    @clearOutput()
    return Promise.resolve(
    ).then(=>
      return @_buildSketch(force, true)
    ).then(=>
      return @_transferSketch(force, true)
    ).then(=>
      bootItem = sketch.bootItem
      unless bootItem?
        App.popupError(i18n.__("No_program_to_boot"))
        return Promise.reject(Error("No program to boot"))
      return Promise.resolve(
      ).then(=>
        $(".sketch-run").closest(".btn-group").hide()
        $(".sketch-stop").show()
      ).then(=>
        started = null
        @_running = new Promise((resolve, reject) =>
          started = board.startSketch(bootItem.path, (result) =>
            return reject() unless result
            return resolve()
          )
        ).finally(=>
          $(".sketch-stop").hide()
          $(".sketch-run").closest(".btn-group").show()
          @_running = null
        )
        return started
      ).then((console) =>
        @_console = console
        @_console.addEventListener("receive.console", this)
        @_console.addEventListener("close.console", this)
        return @_console.open()
      ).then(=>
        @printSystem("-------- #{i18n.__("Connected_to_console")} --------")
        return
      ).catch((error) =>
        $(".sketch-stop").hide()
        $(".sketch-run").closest(".btn-group").show()
        return Promise.reject(error)
      )
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
    unless board.stopSketch?
      App.popupError(
        I18n.translateText("""
          {This_board_does_not_support_stopping_sketch}<br>
          {Reset_board_by_power_cycle}
        """)
      )
      return
    spin = @modalSpin().show()
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
        @SCAN_PERIOD_MS
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
    spin = @modalSpin().text(i18n.__("Connecting")).show()
    Promise.resolve(
    ).then(=>
      return unless @_board.connected
      return @_board.disconnect()
    ).then(=>
      return @_board.connect(@_boardPath)
    ).timeout(
      @CONNECT_TIMEOUT
    ).catch((error) =>
      App.popupError(
        error.toString()
        i18n.__("Failed_to_connect_board")
      )
      return
    ).finally(=>
      spin.hide(500)
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
    switch event.type
      when "setboard.sketch"
        @_board?.disconnect() if @_board?.connected
        @_board = @_sketch?.board
        App.info("Board changed (%o)", @_board)
        @_board?.addEventListener("connect.board", this)
        @_board?.addEventListener("disconnect.board", this)
        @_updateElementsForBoard()
        @_needRegenerate = true
        @_regenerate()
      when "save.sketch"
        @_updateTabTitle(editor) for editor in @_editors
      when "connect.board"
        App.popupInfo(i18n.__("Connected_to_board_at_1", @_boardPath))
        $("body").addClass("board-connected")
        $("#device-selected").text(@_boardPath)
        $(".sketch-run,.sketch-stop,.board-info")
          .prop("disabled", false)
          .next(".dropdown-toggle").prop("disabled", false)
      when "disconnect.board"
        App.popupWarning(i18n.__("Disconnected_from_board_at_1", @_boardPath))
        $("body").removeClass("board-connected")
        $("#device-selected").text("")
        $(".sketch-run,.sketch-stop,.board-info")
          .prop("disabled", true)
          .next(".dropdown-toggle").prop("disabled", true)
        $(".sketch-stop").hide()
        $(".sketch-run").closest(".btn-group").show()
        @_running = null
        @_boardPath = null
      when "changetitle.editor", "change.editor"
        @_updateTabTitle(event.target)
      when "receive.console"
        return unless @_console
        return ab2str(event.data).then((text) =>
          @printOutput(text)
        )
      when "close.console"
        @printSystem("-------- #{i18n.__("Disconnected_from_console")} --------")
        @_console = null
        $(".sketch-stop").hide()
        $(".sketch-run").closest(".btn-group").show()
    return

  ###*
  @private
  @method
    Clear editors
  ###
  _clearEditors: ->
    @_activeEditor?.deactivate()
    @_activeEditor = null
    @_editors.splice(0, @_editors.length)
    $(@_tabSet.domObject).find(@TAB_SELECTOR).remove()
    return

  ###*
  @private
  @method
    Update tab title
  @param {Editor} editor
    Editor instance
  @return {undefined}
  ###
  _updateTabTitle: (editor) ->
    tab = @_getTab(editor)
    tab.find("span.editor-modified").toggle(!!editor.modified)
    tab.find("a").text(editor.title)
    return

  ###*
  @private
  @method
    Select an editor tab
  @param {Editor} editor
    Selected editor
  @return {boolean}
  ###
  _activateEditor: (editor) ->
    return false unless @_editors.includes(editor)
    return true if editor == @_activeEditor
    @_activeEditor?.deactivate()
    (@_activeEditor = editor).activate()
    return true

  ###*
  @static
  @private
  @method
    Get recent sketch descriptors
  @return {Promise}
    Promise object
  @return {Object[]} return.PromiseValue
    Array of descriptor
  ###
  @_getRecentSketches: ->
    return Promise.resolve(
    ).then(=>
      return global.rubic.settings.get({
        "#{@KEY_RECENT_SKETCHES_MAX}": @DEF_RECENT_SKETCHES_MAX
        "#{@KEY_RECENT_SKETCHES_ITEMS}": []
      })
    ).then((values) =>
      max = values[@KEY_RECENT_SKETCHES_MAX]
      items = values[@KEY_RECENT_SKETCHES_ITEMS]
      items.sort((a, b) =>
        return b.lastUsed - a.lastUsed
      )
      items.push({lastUsed: 0}) while items.length < max
      return items.slice(0, max)
    ) # return Promise.resolve().then()...

  ###*
  @static
  @private
  @method
    Update recent sketch list
  @param {Sketch} sketch
    Sketch
  @param {string} [oldFriendlyName=null]
    Old sketch name
  @param {string} [oldFsType=null]
    Old filesystem type identifier
  @return {Promise}
    Promise object
  @return {boolean} return.PromiseValue
    Result (true for succeeded)
  ###
  @_updateRecentSketch: (sketch, oldFriendlyName, oldFsType) ->
    return Promise.resolve(
    ).then(=>
      return @_getRecentSketches()
    ).then((items) =>
      max = items.length
      if oldFriendlyName? and oldFsType == AsyncFs.TEMPORARY
        for item, index in items
          if item.friendlyName == oldFriendlyName
            items.splice(index, 1)
            break
      return sketch.dirFs.retainfs(
      ).then((retainInfo) =>
        newName = sketch.friendlyName?.toString()
        return unless newName?
        for item, index in items
          if item.friendlyName == newName
            items.splice(index, 1)
            break
        items.unshift({
          friendlyName: newName
          lastUsed: Date.now()
          fsType: sketch.dirFs.fsType
          retainInfo: retainInfo
        })
        items = items.slice(0, max)
        return global.rubic.settings.set({"#{@KEY_RECENT_SKETCHES_ITEMS}": items})
      ) # return sketch.dirFs.retainfs().then()
    ).then(=>
      return true
    ).catch((error) =>
      App.error(error)
      return false
    ) # return Promise.resolve().then()...

  ###*
  @private
  @method
    Clear recent sketch list
  @param {Event} event
    Event object
  @return {undefined}
  ###
  _clearRecentSketch: (event) ->
    return

