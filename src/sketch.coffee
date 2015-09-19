class Sketch
  #----------------------------------------------------------------
  # Private constants

  CONFIG_FILE = "sketch.yml"  # Configuration file name
  TEMP_QUOTA  = 1*1024*1024   # Quota (in bytes) for TEMPORARY filesystem

  #----------------------------------------------------------------
  # Class attributes/methods

  ###*
  Open an existing sketch / Create a new sketch
  @param {DirectoryEntry} dirEntry  Directory to open (if null, create new one)
  @param {Function}       callback  Callback ({Boolean} result, {Sketch} sketch)
  ###
  @open: (dirEntry, callback) ->
    return @create(callback) unless dirEntry
    FileUtil.readText(
      [dirEntry, CONFIG_FILE]
      (result, readdata) =>
        unless result
          App.lastError = "Failed to open sketch (Cannot open #{CONFIG_FILE})"
          return callback?(false)
        callback?(true, new this(dirEntry, jsyaml.safeLoad(readdata)))
    ) # FileUtil.readText

  ###*
  Create a new sketch
  @param {Function} callback  Callback ({Boolean} result, {Sketch} sketch)
  ###
  @create: (callback) ->
    failed = (detail) ->
      App.lastError = "Failed to create sketch (#{detail})"
      callback?(false)
    window.webkitRequestFileSystem(
      TEMPORARY
      TEMP_QUOTA
      (fs) =>
        now = new Date
        base = "unnamed_#{now.getFullYear()*10000+(now.getMonth()+1)*100+now.getDate()}"
        Async.each(
          [1..26]
          (num, next, done) =>
            name = base + String.fromCharCode(0x60 + num)
            fs.root.getDirectory(
              name
              {create: true, exclusive: false}
              (dirEntry) =>
                @saveEmptySketch(dirEntry, (result) =>
                  return next() unless result
                  @open(dirEntry, (result, sketch) ->
                    sketch.isTemporary = true if result
                    callback?(result, sketch)
                  )
                ) # @saveEmptySketch
              next
            ) # fs.root.getDirectory()
          -> failed("Directory already exists")
        ) # Async.each()
      -> failed("Failed to request file system")
    ) # window.webkitRequestFileSystem()

  ###*
  Save a new empty sketch
  @param {Function} callback  Callback ({Boolean} result)
  ###
  @saveEmptySketch: (dirEntry, callback) ->
    suffix = App.defaultSuffix
    bootFile = "main#{suffix}"
    config = {
      bootFile: bootFile
      sketch: {
        files: {}
        downloadAll: false
      }
    }
    config.sketch.files[bootFile] = {}
    FileUtil.writeText(
      [dirEntry, CONFIG_FILE]
      jsyaml.safeDump(config)
      (result) =>
        return callback?(false) unless result
        FileUtil.writeText(
          [dirEntry, bootFile]
          @template[suffix]
          callback
        ) # FileUtil.writeText
    ) # FileUtil.writeText

  #----------------------------------------------------------------
  # User interface

  ###
  [UI event] Application started => Open an empty sketch
  ###
  $(=> @uiNewSketch())

  ###*
  [UI action] New sketch
  ###
  @uiNewSketch: (callback) ->
    #return HardwareCatalog.show()
    if App.sketch
      return @uiCloseSketch((result) =>
        return callback?(false) unless result
        App.sketch = null
        @uiNewSketch(callback)
      )
    @create(
      (result, sketch) ->
        return callback?(false) unless result
        App.sketch = sketch
        # console.log({"New sketch": sketch})
        sketch.openEditor(
          sketch.config.bootFile
          (result, editor) ->
            editor.load(->
              editor.activate()
              callback?(true)
            )
        ) # sketch.openEditor
    ) # @create

  ###
  [UI event] Clicking "New sketch" button
  ###
  $(".action-new-sketch").click(=> @uiNewSketch())
  App.bindKey("Ctrl+N", "New sketch", => @uiNewSketch())

  ###*
  [UI action] Open sketch
  ###
  @uiOpenSketch: (callback) ->
    if App.sketch
      return @uiCloseSketch((result) =>
        return callback?(false) unless result
        App.sketch = null
        @uiOpenSketch(callback)
      )
    # TODO: select location (GoogleDrive/LocalStorage/Browser/etc.)
    App.showModalSpin()
    final = (result, sketch) ->
      App.hideModalSpin()
      unless result
        App.error(App.lastError)
        return callback?(false)
      App.sketch = sketch
      sketch.openEditor(
        sketch.config.bootFile
        (result, editor) ->
          return callback?(false) unless result
          editor.load(->
            boardName = sketch.config.sketch?.board?.class
            Board.selectBoard(boardName) if boardName
            editor.activate()
            callback?(true)
          )
      ) # sketch.openEditor

    chrome.fileSystem.chooseEntry({type: "openDirectory"}, (dirEntry) =>
      unless dirEntry
        # cancelled by user
        chrome.runtime.lastError
        return final(true)  # close spin without error message
      @open(dirEntry, final)
    ) # chrome.fileSystem.chooseEntry

  ###
  [UI event] Clicking "Open sketch" button
  ###
  $(".action-open-sketch").click(=>
    Editor.focus()
    @uiOpenSketch()
  )
  App.bindKey("Ctrl+O", "Open sketch", => @uiOpenSketch())

  ###*
  [UI action] Save sketch (overwrite)
  ###
  @uiSaveSketch: (callback) ->
    sketch = App.sketch
    return App.warning("No sketch to save") unless sketch
    App.showModalSpin()
    sketch.save((result) ->
      if result
        App.success("Sketch has been saved.")
      else
        App.error(App.lastError)
      App.hideModalSpin()
      callback?(result)
    )

  ###
  [UI event] Clicking "Save sketch" button
  ###
  $(".action-save-sketch").click(=>
    Editor.focus()
    # return @uiSaveSketchAs() if App.sketch?.isTemporary
    @uiSaveSketch()
  )
  App.bindKey("Ctrl+S", "Save sketch", => @uiSaveSketch())

  ###*
  [UI action] Save sketch (to new location)
  ###
  @uiSaveSketchAs: (callback) ->
    sketch = App.sketch
    return App.warning("No sketch to save") unless sketch
    App.showModalSpin()
    final = (result) ->
      App.error(App.lastError) unless result
      App.hideModalSpin()
      callback?(result)
    chrome.fileSystem.chooseEntry({type: "openDirectory"}, (dirEntry) =>
      unless dirEntry
        # cancelled by user
        chrome.runtime.lastError
        return final(true)  # close spin without error message
      # console.log({saveAs: dirEntry})
      FileUtil.readText([dirEntry, CONFIG_FILE], (result) ->
        return App.error("Another sketch has been saved in selected directory. Choose an empty one.") if result
        sketch.saveAs(dirEntry, (result) ->
          App.error("Failed to save sketch (#{App.lastError})") unless result
          App.hideModalSpin()
        )
      ) # FileUtil.readText
    ) # chrome.fileSystem.chooseEntry

  ###
  [UI event] Clicking "Save as..." button
  ###
  $(".action-save-sketch-as").click(=>
    Editor.focus()
    @uiSaveSketchAs()
  )
  App.bindKey("Ctrl+Shift+S", "Save sketch as", => @uiSaveSketchAs())

  ###*
  [UI action] Close sketch
  @param {Function} callback  Callback ({Boolean} result)
  ###
  @uiCloseSketch: (callback) ->
    return callback?(true) unless App.sketch
    unless App.sketch.modified
      return App.sketch.close((result) ->
        App.sketch = null if result
        return callback?(result)
      )

    # Not saved
    bootbox.dialog({
      title: "Current sketch has been modified"
      message: "Are you want to discard modifications?"
      buttons: {
        discard: {
          label: "Yes. I discard them."
          className: "btn-danger"
          callback: ->
            App.sketch.close((result) ->
              App.sketch = null if result
              callback?(result)
            )
        }
        save: {
          label: "No. I want to save before close."
          className: "btn-success"
          callback: => @uiSaveSketch(callback)
        }
      }
    })  # bootbox.dialog

  ###*
  [UI action] Build sketch
  ###
  @uiBuildSketch: (callback) ->
    sketch = App.sketch
    unless sketch
      App.error("No sketch to build")
      return callback?(false)
    App.showModalSpin() unless callback
    progress = App.info("Building...")
    sketch.build((result, message) ->
      progress.close()
      App.hideModalSpin() unless callback
      if result
        App.success("Build succeeded (#{message})") unless callback
        # # for debugging
        # sketch.openEditor("main.mrb", (result, sketch) -> sketch.load())
      else
        App.error("Build failed (#{App.lastError})")
      callback?(result)
    )

  ###
  [UI event] Clicking "Build" button
  ###
  $(".action-build-sketch").click(=>
    Editor.focus()
    @uiBuildSketch()
  )
  App.bindKey("Ctrl+B", "Build", => @uiBuildSketch())

  #----------------------------------------------------------------
  # Instance attributes/methods

  ###*
  @property {DirectoryEntry}
  @readonly
  DirectoryEntry of directory which contains sketch files
  ###
  dirEntry: null

  ###*
  @property {Object}
  Configuration of sketch
  ###
  config: null

  ###*
  @property {String}
  @readonly
  Name of sketch
  ###
  name: null

  ###*
  @property {Board}
  @readonly
  Board selection
  ###
  board: null

  ###*
  @property {Editor[]}
  @readonly
  List of opened editors
  ###
  editors: []

  ###*
  @property {Boolean}
  @readonly
  Saved in TEMPORARY storage
  ###
  isTemporary: false

  ###*
  @property {Boolean}
  @readonly
  Is sketch modified?
  ###
  modified: false

  ###*
  Mark as modified
  ###
  markModified: (value = true) ->
    @modified = value

  ###*
  Set board of sketch
  @param {Function} boardClass  Constructor of new board
  @param {Function} callback    Callback ({Boolean} result, {Board} board instance)
  ###
  setBoard: (boardClass, callback) ->
    ((@config.sketch or= {}).board or= {}).class = boardClass.name
    @board or= {disconnect: (callback) -> callback?(true)}
    @board.disconnect((result) =>
      return callback?(false) unless result
      @board = new boardClass()
      callback?(true, @board)
    ) # @board.disconnect

  ###*
  Open an editor for a single file
  @param {Function} callback  Callback ({Boolean} result, {Editor} editor)
  ###
  openEditor: (path, callback) ->
    FileUtil.readEntries(
      @dirEntry
      (entries) =>
        for e in entries
          continue unless e.name == path
          editor = Editor.open(e)
          @editors.push(editor)
          callback?(true, editor)
      -> callback?(false)
    ) # FileUtil.readEntries

  ###*
  Save sketch (including all files in sketch)
  @param {Function} callback  Callback ({Boolean} result)
  ###
  save: (callback) ->
    @saveAs(null, callback)

  ###*
  Save to another directory
  @param {DirectoryEntry} dirEntry  New directory to store sketch files @nullable
  @param {Function}       callback  Callback ({Boolean} result)
  ###
  saveAs: (dirEntry, callback) ->
    Async.apply_each(
      @editors
      (next, abort) ->
        @saveAs(dirEntry, (result) -> if result then next() else abort())
      (done) =>
        return callback?(false) unless done
        @dirEntry = dirEntry if dirEntry
        @name = @dirEntry.name
        $("li#sketch").text("[Sketch] #{@name}")
        @saveConfig((result) ->
          @modified = false if result
          callback?(result)
        )
    ) # Async.apply_each

  ###*
  Save configuration
  @param {Function} callback  Callback ({Boolean} result)
  ###
  saveConfig: (callback) ->
    manifest = chrome.runtime.getManifest()
    (@config.sketch or= {}).rubicVersion or= manifest.version
    FileUtil.writeText(
      [@dirEntry, CONFIG_FILE]
      jsyaml.safeDump(@config)
      callback
    ) # FileUtil.writeText

  ###*
  Close sketch
  ###
  close: (callback) ->
    @board or= {disconnect: (callback) -> callback?(true)}
    @board.disconnect((result) =>
      Async.apply_each(
        @editors,
        (next, abort) ->
          this.close((result) -> if result then next() else abort())
        (done) ->
          $("li#sketch").remove() if done
          callback?(done)
      ) # Async.apply_each
    ) # @board.disconnect

  ###*
  Build sketch
  @param {Function} callback  Callback ({Boolean} result, {String} usage)
  ###
  build: (callback) ->
    total_length = 0
    Async.each(
      (name for name of @config.sketch.files)
      (name, next, abort) =>
        @dirEntry.getFile(
          name
          {}
          (fileEntry) =>
            cfg = @config.sketch.files[name]
            return next() if cfg.build? and (not cfg.build)
            builder = Builder.createBuilder(
              @dirEntry
              fileEntry
              cfg.build_options
              cfg.builder
            )
            unless builder
              return abort() if cfg.build
              cfg.build = false
              return next()
            builder.build(
              (result, length) ->
                return abort() unless result
                # console.log({len: length})
                total_length += length
                next()
            ) # builder.build
          abort
        ) # @dirEntry.getFile
      (done) ->
        return callback?(false) unless done
        usage = "#{(total_length/1024).toFixed(1)} kB used"
        callback?(true, usage)
    ) # Async.apply

  ###*
  @private
  Constructor
  @param {DirectoryEntry} dirEntry    Directory to be associated with this sketch
  @param {Object}         config      Initial configuration
  ###
  constructor: (@dirEntry, @config) ->
    @name = @dirEntry.name
    li = $("<li id=\"sketch\">[Sketch] #{@name}</li>")
    li.click(-> App.info("Sketch configuration editor is not implemented yet. Sorry."))
    $("#file-tabbar").append(li)

  ###*
  @property {Object} template
  @readonly
  Template source code for each language
  ###
  @template: {
    ".rb":
      """
      #!mruby

      """
  }

