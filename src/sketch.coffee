class Sketch
  @defaultSuffix: ".rb"
  @quota: 1*1024*1024
  @template: {
    ".rb":
      """
      # Hello mruby world!
      # Write your code

      """
  }
  @instance: null

  dirEntry: null
  config: null
  name: null
  editors: []

  @property('board',
    get: -> @_board
    set: (b) ->
      @_board = b
      @_board.selected()
  )

  ###*
  Open an existing sketch / Create a new sketch
  @param dirEntry         Directory to open (if null, create new one)
  @param successCallback  Callback on success
  @param errorCallback    Callback on error (optional)
  ###
  @open: (dirEntry, successCallback, errorCallback) ->
    return Sketch.create(successCallback, errorCallback) unless dirEntry
    errorCallback or= -> null
    FileUtil.readText(
      dirEntry,
      "sketch.json",
      null,
      ((json) ->
        if json
          successCallback(new Sketch(dirEntry, JSON.parse(json)))
        else
          errorCallback()
      ),
      errorCallback
    )

  ###*
  Create a new sketch
  @param successCallback  Callback on success
  @param errorCallback    Callback on error (optional)
  ###
  @create: (successCallback, errorCallback) ->
    errorCallback or= -> null
    window.webkitRequestFileSystem(
      TEMPORARY,
      Sketch.quota,
      ((fs) ->
        now = new Date
        m2s = ["jan", "feb", "mar", "apr", "may", "jun",
               "jul", "aug", "sep", "oct", "nov", "dec"]
        base = "sketch_#{m2s[now.getMonth()] + now.getDate()}"
        AsyncFor(
          [1..26],
          ((next, done) ->
            fs.root.getDirectory(
              base + String.fromCharCode(0x60 + this),
              {create: true, exclusive: false},
              ((dirEntry) ->
                suffix = Sketch.defaultSuffix
                bootFile = "main#{suffix}"
                FileUtil.writeText(
                  dirEntry,
                  "sketch.json",
                  "{\"bootFile\": \"#{bootFile}\"}",
                  (->
                    FileUtil.writeText(
                      dirEntry,
                      bootFile,
                      Sketch.template[suffix],
                      (-> Sketch.open(dirEntry, done, next)
                      ),
                      next
                    )
                  ),
                  next
                )
              ),
              next
            ) # fs.root.getDirectory()
          ),  # (next, done) ->
          ((sketch) ->
            errorCallback() unless sketch
            successCallback(sketch)
          )
        ) # async_for()
      ),  # (fs) ->
      errorCallback
    ) # window.webkitRequestFileSystem()

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
  build: (successCallback, errorCallback) -> do (self = this) ->
    FileUtil.readEntries(
      self.dirEntry,
      ((entries) ->
        AsyncFor(
          entries,
          ((next, abort) ->
            builder = Builder.createBuilder(self.dirEntry, this)
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

#  sketch = null # An instance of current sketch
#  sketch = new Sketch
$(->
  Sketch.create(
    ((sketch) ->
      App.sketch = sketch
      console.log({"New sketch": sketch})
      sketch.openEditor(sketch.config.bootFile,
        ((e) ->
          e.load(->
            e.activate()
          )
        )
      )
    ),
    -> null
  )
)
$("#save-sketch").click(->
  App.sketch.build(->
    console.log({"build succeeded": arguments})
  )
)
