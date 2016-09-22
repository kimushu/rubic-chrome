"use strict"
# Pre dependencies
WindowController = require("controller/windowcontroller")
require("util/primitive")

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
  KEY_RECENT_SKETCHES_MAX = "recent_sketches.max"
  DEF_RECENT_SKETCHES_MAX = 10
  KEY_RECENT_SKETCHES_ITEMS = "recent_sketches.items"
  KEY_DEFPLACE = "default_place"
  PLACES = ["local", "googledrive", "dropbox", "onedrive"]
  MIN_SAVE_SPIN = 400
  TAB_SELECTOR = "li.editor-tab"

  firstActivation = true  # Flag for first activation
  tabSet = null           # jquery-scrollTabs instance for editor tabs
  Ace = null              # Ace class
  aceEditor = null        # Ace editor for output window
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
        click_callback: (event) =>
          index = $(event.currentTarget).prevAll(TAB_SELECTOR).length
          editor = @_editors[index]
          return unless editor?
          if $(event.target).hasClass("editor-close-button")
            Promise.resolve(
            ).then(=>
              return "ok" unless editor.modified
              return App.safeConfirm_yes_no(
                rawTitle: I18n.getMessage("File_1_has_been_modified", editor.sketchItem?.path)
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
      })
      App.log("MainController.tabSet: %o", tabSet)
      return
    ).then(=>
      # Setup Ace editor for output window (only once)
      return unless firstActivation
      Ace = window.ace
      Ace.Range = Ace.require("ace/range").Range
      aceEditor = Ace.edit($(".editor-bottom")[0])
      App.log("MainController.aceEditor: %o", aceEditor)
      aceEditor.$blockScrolling = Infinity
      aceEditor.renderer.setShowGutter(false)
      aceEditor.setTheme("ace/theme/twilight")
      aceEditor.setShowPrintMargin(false)
      # aceEditor.setReadOnly(true)
      return
    ).then(=>
      # Setup other HTML elements (only once)
      return unless firstActivation
      $(".sketch-new")          .click(@_newSketch.bind(this))
      $(".sketch-open-latest")  .click(@_openSketch.bind(this, null, null))
      $(".sketch-open-local")   .click(@_openSketch.bind(this, "local", null))
      $(".sketch-save-overwrite").click(@_saveSketch.bind(this, null))
      $(".sketch-save-local")   .click(@_saveSketch.bind(this, "local"))
      $(".sketch-close")        .click(@_closeSketch.bind(this, false, false))
      $(".sketch-build")        .click(@_buildSketch.bind(this))
      $(".sketch-run")          .click(@_runSketch.bind(this))
      $(".sketch-stop").hide()  .click(@_stopSketch.bind(this))
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
        @_board?.getBoardInfo().then((info) =>
          table = $("#template-table").children().clone()
          $("#template-tr-th11").children().clone()
            .appendTo(table.find("thead")).find("th")
            .eq(0).text(I18n.getMessage("Board_info")).end()
            .eq(1).text("#{@_board.friendlyName} [#{@_board.path}]").end()
          for k, v of info
            $("#template-tr-td11").children().clone()
              .appendTo(table.find("tbody")).find("td")
              .eq(0).text(I18n.translateText(k)).end()
              .eq(1).text(v).end()
          return global.bootbox.alert_p({
            # title: I18n.getMessage("Board_info")
            message: table
          })
        ) # @_board?.getBoardInfo().then()
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
    ) # return super().then()...

  ###*
  @protected
  @inheritdoc Controller#deactivate
  ###
  deactivate: ->
    $ = @$
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
    $ = @$
    exists = @_editors.indexOf(editor)
    if exists >= 0
      position = exists
    else
      position ?= @_editors.length
      @_editors.splice(position, 0, editor)
      s = TAB_SELECTOR.split(".")
      tabSet.addTab("""
      <#{s[0]} class="#{s[1]}">
        <span class="editor-modified fa fa-pencil"></span>
        <span class="editor-readonly fa fa-lock"></span>
        <a href="#"></a>
        <span class="editor-close-button glyphicon glyphicon-remove"></span>
      </#{s[0]}>
      """, position)
      tab = $(tabSet.domObject).find(TAB_SELECTOR).eq(position)
      tab.find("a").eq(0).text(editor.title or "")
      tab.find("span.editor-modified").hide() unless editor.modified
      tab.find("span.editor-readonly").hide() if editor.editable
      tab.find("span.editor-close-button").remove() unless editor.closable
      editor.addEventListener("changetitle.editor", this)
      editor.addEventListener("change.editor", this)
      App.log("New editor (%o) at index %d", editor, position)
    $(tabSet.domObject).find(TAB_SELECTOR).eq(position).click() if activate
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
      $(tabSet.domObject).find(TAB_SELECTOR).eq(position).remove()
      position = Math.min(position, @_editors.length - 1)
      $(tabSet.domObject).find(TAB_SELECTOR).eq(position).click() if position >= 0
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
    aceEditor.setSession(session)
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
    session = aceEditor.getSession()
    range = new Ace.Range
    row = session.getLength()
    range.start = {
      row: row
      column: session.getLine(row).length
    }
    if newline and range.start.column > 0
      text = "\n#{text}"
    range.end = session.insert(range.start, text)
    session.addMarker(range, "marker-#{marker}", "text") if marker?
    return

  ###*
  @method
    Print system message to output window
  @param {string} text
    Text to print (LF automatically added to the end of text)
  @return {undefined}
  ###
  printSystem: (text) ->
    @printOutput("#{text}\n", "system", true)
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
    return $(tabSet.domObject).find(TAB_SELECTOR).eq(position)

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
    return Promise.resolve() unless noSketch

    # Construct welcome page
    tabSet.clearTabs()
    tabSet.addTab("<li id=\"editor-welcome\">#{I18n.getMessage("Welcome")}</li>")
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
            .eq(0).text(I18n.getMessage("Open_sketch_1", item.friendlyName)).end()
            .eq(1).html("""
            #{I18n.getMessage("Stored_location")}: #{
              I18n.getMessage("fsType_#{item.fsType}")
            }&nbsp;&nbsp;/&nbsp;&nbsp;#{
              I18n.getMessage("Last_used_time")}: #{
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
    @_editors = []
    tabSet.clearTabs()
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
      return "yes" unless App.sketch?.modified
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
        return {"#{KEY_DEFPLACE}": place} if place != "latest"
        return Preferences.get({"#{KEY_DEFPLACE}": "local"})
      ).then((value) =>
        place = value[KEY_DEFPLACE]
        return @_closeSketch(true)
      ).then(=>
        switch(place)
          when "local"
            return AsyncFs.chooseDirectory().catch(=> return)
        return Promise.reject(Error("Unsupported place (#{place})"))
      ) # return Promise.resolve().then()...
    ).then((fs) =>
      return unless fs?
      return Sketch.open(fs).then((sketch) =>
        @_setSketch(sketch)
        return Promise.resolve(
        ).then(=>
          return @_restoreWorkspace()
        ).then(=>
          return @constructor._updateRecentSketch(sketch)
        )
      ).then(=>
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
    Save sketch
  @param {"overwrite"/"local"} [place="overwrite"]
  @return {Promise}
    Promise object
  ###
  _saveSketch: (place = "overwrite") ->
    return Promise.reject(Error("No sketch to save")) unless @_sketch?
    spin = @modalSpin().text(I18n.getMessage("Saving_sketch")).show()
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
        return Preferences.set({"#{KEY_DEFPLACE}": place})
      ).then(=>
        return newDirFs
      ).catch((error) =>
        App.popupWarning(I18n.getMessage("Sketch_save_canceled"))
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
      App.popupSuccess(I18n.getMessage(id))
      return  # Do not wait until notification closing
    ).finally(=>
      spin.hide(MIN_SAVE_SPIN)
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
        (path, progress, error) =>
          return App.popupError(
            I18n.getMessage("Failed_to_build_1", path)
            I18n.getMessage("Build_failed")
          ) if error?
          msg = I18n.getMessage("Building_1", path)
          @printSystem(msg) if progress == 0
          spin.text(
            "#{msg} (#{Math.round(progress)}%)"
          )
          return
      ).then(=>
        msg = I18n.getMessage("Build_succeeded")
        @printSystem(msg)
        App.popupSuccess(msg)
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
        (path, progress, error) =>
          return App.popupError(
            I18n.getMessage("Failed_to_transfer_1", path)
            I18n.getMessage("Transfer_failed")
          ) if error?
          msg = I18n.getMessage("Transferring_1", path)
          @printSystem(msg) if progress == 0
          return spin.text(
            "#{msg} (#{Math.round(progress)}%)"
          )
      ).then(=>
        msg = I18n.getMessage("Transfer_succeeded")
        @printSystem(msg)
        App.popupSuccess(msg)
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
    $ = @$
    sketch = App.sketch
    return Promise.reject(Error("No sketch to run")) unless sketch?
    board = sketch.board
    return Promise.reject(Error("No board")) unless board?
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
        App.popupError(I18n.getMessage("No_program_to_boot"))
        return Promise.reject(Error("No program to boot"))
      @_running = Promise.resolve(
      ).then(=>
        $(".sketch-run").closest(".btn-group").hide()
        $(".sketch-stop").show()
      ).then(=>
        return board.startSketch(bootItem)
      ).then((console) =>
        @_console = console
        @_console.addEventListener("receive.console", this)
        @_console.addEventListener("close.console", this)
        return @_console.open()
      ).then(=>
        @printSystem("-------- #{I18n.getMessage("Connected_to_console")} --------")
        return
      ).finally(=>
        $(".sketch-stop").hide()
        $(".sketch-run").closest(".btn-group").show()
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
    ).catch((error) =>
      App.popupError(
        error.toString()
        I18n.getMessage("Failed_to_connect_board")
      )
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
        App.popupInfo(I18n.getMessage("Connected_to_board_at_1", @_boardPath))
        $("body").addClass("board-connected")
        $("#device-selected").text(@_boardPath)
        $(".sketch-run").prop("disabled", false).next().prop("disabled", false)
        $(".board-info").prop("disabled", false)
      when "disconnect.board"
        App.popupWarning(I18n.getMessage("Disconnected_from_board_at_1", @_boardPath))
        $("body").removeClass("board-connected")
        $("#device-selected").text("")
        $(".sketch-run").prop("disabled", true).next().prop("disabled", true)
        $(".board-info").prop("disabled", true)
        @_boardPath = null
      when "changetitle.editor", "change.editor"
        @_updateTabTitle(event.target)
      when "receive.console"
        return unless @_console
        return ab2str(event.data).then((text) =>
          @printOutput(text)
        )
      when "close.console"
        @printSystem("-------- #{I18n.getMessage("Disconnected_from_console")} --------")
        @_console = null
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
    $(tabSet.domObject).find(TAB_SELECTOR).remove()
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
      return Preferences.get({
        "#{KEY_RECENT_SKETCHES_MAX}": DEF_RECENT_SKETCHES_MAX
        "#{KEY_RECENT_SKETCHES_ITEMS}": []
      })
    ).then((values) =>
      max = values[KEY_RECENT_SKETCHES_MAX]
      items = values[KEY_RECENT_SKETCHES_ITEMS]
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
        return Preferences.set({"#{KEY_RECENT_SKETCHES_ITEMS}": items})
      ) # return sketch.dirFs.retainfs().then()
    ).then(=>
      return true
    ).catch((error) =>
      App.error(error)
      return false
    ) # return Promise.resolve().then()...

# Post dependencies
I18n = require("util/i18n")
Preferences = require("app/preferences")
App = require("app/app")
Sketch = require("sketch/sketch")
AsyncFs = require("filesystem/asyncfs")
SketchItem = require("sketch/sketchitem")
Editor = require("editor/editor")
SketchEditor = require("editor/sketcheditor")
sprintf = require("util/sprintf")
ab2str = require("util/ab2str")
