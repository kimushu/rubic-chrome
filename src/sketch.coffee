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
          return callback(false)
        callback(true, new this(dirEntry, jsyaml.safeLoad(readdata)))
    ) # FileUtil.readText

  ###*
  Create a new sketch
  @param {Function} callback  Callback ({Boolean} result, {Sketch} sketch)
  ###
  @create: (callback) ->
    failed = (detail) ->
      App.lastError = "Failed to create sketch (#{detail})"
      callback(false)
    window.webkitRequestFileSystem(
      TEMPORARY
      TEMP_QUOTA
      (fs) =>
        now = new Date
        base = "sketch_#{now.getFullYear()*10000+(now.getMonth()+1)*100+now.getDate()}"
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
                    callback(result, sketch)
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
      sketch: {files: {}, downloadAll: false}
    }
    config.sketch.files[bootFile] = {}
    FileUtil.writeText(
      [dirEntry, CONFIG_FILE]
      jsyaml.safeDump(config)
      (result) =>
        return callback(false) unless result
        FileUtil.writeText(
          [dirEntry, bootFile]
          @template[suffix]
          callback
        ) # FileUtil.writeText
    ) # FileUtil.writeText

  #----------------------------------------------------------------
  # User interface

  ###*
  [UI action] Open sketch
  ###
  @uiOpenSketch: (callback) ->
    # TODO: select location (GoogleDrive/LocalStorage/Browser/etc.)
    ModalSpin.show()
    final = (result, sketch) ->
      ModalSpin.hide()
      unless result
        Notify.error(App.lastError)
        return callback?(false)
      App.sketch = sketch
      sketch.openEditor(
        sketch.config.bootFile
        (result, editor) ->
          return callback?(false) unless result
          editor.load(->
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
  $("#open-sketch").click(=>
    Editor.focus()
    return @uiOpenSketch() unless App.sketch
    @uiCloseSketch((result) => @uiOpenSketch() if result)
  )

  ###*
  [UI action] Save sketch (overwrite)
  ###
  @uiSaveSketch: (callback) ->
    sketch = App.sketch
    return Notify.warning("No sketch to save") unless sketch
    ModalSpin.show()
    sketch.save((result) ->
      if result
        Notify.success("Sketch has saved.")
      else
        Notify.error(App.lastError)
      ModalSpin.hide()
      callback?(result)
    )

  ###
  [UI event] Clicking "Save sketch" button
  ###
  $("#save-sketch").click(=>
    Editor.focus()
    # return @uiSaveSketchAs() if App.sketch?.isTemporary
    @uiSaveSketch()
  )

  ###*
  [UI action] Save sketch (to new location)
  ###
  @uiSaveSketchAs: (callback) ->
    sketch = App.sketch
    return Notify.warning("No sketch to save") unless sketch
    ModalSpin.show()
    final = (result) ->
      Notify.error(App.lastError) unless result
      ModalSpin.hide()
      callback?(result)
    chrome.fileSystem.chooseEntry({type: "openDirectory"}, (dirEntry) =>
      unless dirEntry
        # cancelled by user
        chrome.runtime.lastError
        return final(true)  # close spin without error message
      sketch.saveAs(dirEntry, (result) ->
        Notify.error("Failed to save sketch (#{App.lastError})") unless result
        ModalSpin.hide()
      )
    ) # chrome.fileSystem.chooseEntry

  ###
  [UI event] Clicking "Save as..." button
  ###
  $("#save-sketch-as").click(=>
    Editor.focus()
    @uiSaveSketchAs()
  )

  ###*
  [UI action] Close sketch
  @param {Function} callback  Callback ({Boolean} result)
  ###
  @uiCloseSketch: (callback) ->
    return callback?(true) unless App.sketch
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
      Notify.error("No sketch to build")
      return callback?(false)
    ModalSpin.show() unless callback
    sketch.build((result, message) ->
      ModalSpin.hide() unless callback
      if result
        Notify.success("Build succeeded (#{message})") unless callback
      else
        Notify.error("Build failed (#{App.lastError})")
      callback?(result)
    )

  ###
  [UI event] Clicking "Build" button
  ###
  $("#build").click(=>
    Editor.focus()
    @uiBuildSketch()
  )

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
    @board or= {disconnect: (callback) -> callback(true)}
    @board.disconnect((result) =>
      return callback(false) unless result
      @board = new boardClass()
      callback(true, @board)
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
          callback(true, editor)
      -> callback(false)
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
        return callback(false) unless done
        @dirEntry = dirEntry if dirEntry
        @saveConfig((result) ->
          @modified = false if result
          callback(result)
        )
    ) # Async.apply_each

  ###*
  Save configuration
  @param {Function} callback  Callback ({Boolean} result)
  ###
  saveConfig: (callback) ->
    FileUtil.writeText(
      [@dirEntry, CONFIG_FILE]
      jsyaml.safeDump(@config)
      callback
    ) # FileUtil.writeText

  ###*
  Close sketch
  ###
  close: (callback) ->
    Async.apply_each(
      @editors,
      (next, abort) ->
        this.close((result) -> if result then next() else abort())
      (done) ->
        callback(done)
    ) # Async.apply_each

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
                console.log({len: length})
                total_length += length
                next()
            ) # builder.build
          abort
        ) # @dirEntry.getFile
      (done) ->
        return callback(false) unless done
        usage = "#{(total_length/1024).toFixed(1)} kB used"
        callback(true, usage)
    ) # Async.apply

  ###*
  @private
  Constructor
  @param {DirectoryEntry} dirEntry    Directory to be associated with this sketch
  @param {Object}         config      Initial configuration
  ###
  constructor: (@dirEntry, @config) ->
    @name = @dirEntry.name

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

  $(=>
    @create(
      (result, sketch) ->
        return unless result
        App.sketch = sketch
        console.log({"New sketch": sketch})
        sketch.openEditor(
          sketch.config.bootFile
          (result, editor) ->
            editor.load(-> editor.activate())
        ) # sketch.openEditor
    ) # @create
  )

#  $("button#save-sketch").click(->
#    App.sketch.build(->
#      console.log({"build succeeded": arguments})
#    )
#  )
