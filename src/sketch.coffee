class Sketch
  ###*
  @property {DirectoryEntry} dirEntry
  @readonly
  DirectoryEntry of directory which contains sketch files
  ###
  dirEntry: null

  ###*
  @property {Object} config
  Configuration of sketch
  ###
  config: null

  ###*
  @property {String} name
  @readonly
  Name of sketch
  ###
  name: null

  ###*
  @property {Board} board
  @readonly
  Board selection
  ###
  board: null

  editors: []

  ###*
  Open an existing sketch / Create a new sketch
  @param {DirectoryEntry} dirEntry  Directory to open (if null, create new one)
  @param {Function}       callback  Callback ({Boolean} result, {Sketch} sketch)
  ###
  @open: (dirEntry, callback) ->
    return @create(callback) unless dirEntry
    FileUtil.readText(
      [dirEntry, "sketch.json"],
      null,
      ((result, readdata) =>
        return callback(false) unless result
        callback(true, new this(dirEntry, JSON.parse(readdata)))
      )
    )

  ###*
  Create a new sketch
  @param {Function} callback  Callback ({Boolean} result, {Sketch} sketch)
  ###
  @create: (callback) ->
    window.webkitRequestFileSystem(
      TEMPORARY,
      @quota,
      ((fs) ->
        now = new Date
        m2s = ["jan", "feb", "mar", "apr", "may", "jun",
               "jul", "aug", "sep", "oct", "nov", "dec"]
        base = "sketch_#{m2s[now.getMonth()]}#{now.getDate()}"
        suffix = App.defaultSuffix
        bootFile = "main#{suffix}"
        Async.each(
          [1..26],
          ((num, next, done) =>
            fs.root.getDirectory(
              base + String.fromCharCode(0x60 + num),
              {create: true, exclusive: false},
              ((dirEntry) =>
                FileUtil.writeText(
                  [dirEntry, "sketch.json"],
                  "{\"bootFile\": \"#{bootFile}\"}",
                  ((result) =>
                    return next() unless result
                    FileUtil.writeText(
                      [dirEntry, bootFile],
                      Sketch.template[suffix],
                      ((result) =>
                        return next() unless result
                        Sketch.open(dirEntry, callback)
                      )
                    ) # FileUtil.writeText()
                  )
                ) # FileUtil.writeText()
              ),
              next
            ) # fs.root.getDirectory()
          ),
          (-> callback(false))
        ) # Async.each()
      ),# (fs) ->
      (-> callback(false))
    ) # window.webkitRequestFileSystem()

  ###*
  Change board of sketch
  @param {Board}    new board
  @param {Function} callback ({Boolean} result)
  ###
  changeBoard: (board, callback) ->
    @board or= {disconnect: (cb) -> cb(true)}
    @board.disconnect((result) =>
      return callback(false) unless result
      @board = board
      callback(true)
    )

  ###*
  Open an editor for a single file
  ###
  openEditor: (path, successCallback, errorCallback) ->
    self = this
    FileUtil.readEntries(
      @dirEntry,
      ((entries) ->
        for e in entries
          continue if e.name != path
          editor = Editor.open(e)
          self.editors.push(editor)
          return successCallback(editor)
      ),
      errorCallback
    )

  ###*
  Save sketch (including all files in sketch)
  ###
  save: (successCallback, errorCallback) ->
    errorCallback or= -> null
    AsyncFor(
      @editors,
      ((next, abort) ->
        this.save(next, (-> abort(true)))
      ),
      ((aborted) ->
        return errorCallback() if aborted
        successCallback()
      )
    )

  ###*
  Build sketch
  ###
  build: (successCallback, errorCallback) ->
    FileUtil.readEntries(
      @dirEntry,
      ((entries) =>
        AsyncFor(
          entries,
          ((next, abort) =>
            builder = Builder.createBuilder(@dirEntry, this)
            return next() unless builder
            console.log({"build": builder})
            builder.build(next, abort)
          ),
          ((aborted) ->
            return errorCallback() if aborted
            successCallback()
          )
        )
      ),
      errorCallback
    )

  ###*
  Transport sketch to new location
  ###
  transport: (dirEntry, successCallback, errorCallback) ->
    null

  ###*
  @private
  Construct class
  ###
  constructor: (@dirEntry, @config) ->
    @name = @dirEntry.name

  ###*
  @property {Integer} quota
  @readonly
  Quota size of sketch (in bytes)
  ###
  @quota: 1 * 1024 * 1024

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

  $("#save-sketch").click(=>
    bootbox.dialog(
      title: "Save as ...",
      message: "hogehoge",
    )
  )
  $(=>
    @create(
      ((result, sketch) ->
        return unless result
        App.sketch = sketch
        console.log({"New sketch": sketch})
        sketch.openEditor(sketch.config.bootFile,
          ((e) ->
            e.load(->
              e.activate()
            )
          )
        )
      )
    )
  )

$("button#open-sketch").click(->
  #  ModalSpin.show()
  App.sketch.board.test()
)
#  $("button#save-sketch").click(->
#    App.sketch.build(->
#      console.log({"build succeeded": arguments})
#    )
#  )
