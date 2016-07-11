# Pre dependencies
JSONable = require("./jsonable")
strftime = require("./strftime")

###*
@class Sketch
  Sketch (Model)
@extends JSONable
###
class Sketch extends JSONable
  Sketch.jsonable()

  #--------------------------------------------------------------------------------
  # Public properties
  #

  ###*
  @property {string} friendlyName
    Name of sketch (Same as directory name)
  @readonly
  ###
  @property("friendlyName", get: -> @_dirFs?.name)

  ###*
  @property {boolean} modified
    Is sketch modified
  ###
  @property("modified",
    get: -> @_modified
    set: (v) -> @_setModified() if !!v
  )

  ###*
  @property {boolean} temporary
    Is sketch temporary
  @readonly
  ###
  @property("temporary", get: -> @_temporary)

  ###*
  @property {AsyncFs} dirFs
    File system object for sketch directory
  @readonly
  ###
  @property("dirFs", get: -> @_dirFs)

  ###*
  @property {SketchItem[]} items
    Array of items in sketch
  @readonly
  ###
  @property("items", get: -> (item for item in @_items))

  ###*
  @property {string} bootItem
    Path of boot item
  ###
  @property("bootItem",
    get: -> @_bootItem
    set: (v) ->
      found = null
      for item in @_items
        if item.path == v
          found = item
          break
      throw Error("No item `#{v}'") unless found?
      return if @_bootItem == v
      @_bootItem = v
      return
  )

  ###*
  @property {Board} board
    Board instance
  ###
  @property("board",
    get: -> @_board
    set: (v) ->
      return if @_board == v
      @_board?.onChange?.removeListener?(@_setModifiedCaller)
      @_board = v
      @_board?.onChange?.addListener?(@_setModifiedCaller)
      @_setModified()
  )

  #--------------------------------------------------------------------------------
  # Event listeners
  #

  ###*
  @event onChange
    Changed event target
  ###
  @property("onChange", get: -> @_onChange or= new EventTarget())

  #--------------------------------------------------------------------------------
  # Private constants
  #

  SKETCH_CONFIG   = "sketch.json"
  SKETCH_ENCODING = "utf8"

  #--------------------------------------------------------------------------------
  # Public methods
  #

  ###*
  @static
  @method
    Create empty sketch on temporary storage
  @param {string} [name]
    Name of new sketch
  @return {Promise}
    Promise object
  @return {Sketch} return.PromiseValue
    The instance of sketch
  ###
  @createNew: (name) ->
    name or= strftime("sketch_%Y%m%d_%H%M%S")
    sketch = null
    return AsyncFs.opentmpfs().then((fs) =>
      return fs.opendirfs(name).catch(=>
        return fs.mkdir(name).then(=>
          return fs.opendirfs(name)
        )
      )
    ).then((dirFs) =>
      sketch = new Sketch()
      return sketch.save(dirFs)
    ).then(=>
      # FIXME>>>
      sketch.addItem(i = new SketchItem({path: "main.rb"}))
      sketch.bootItem = "main.rb"
    #   sketch.board = new Board()
    #   return i.setup()
    # ).then(=>
      # <<<FIXME
      sketch._temporary = true
      return sketch
    ) # return AsyncFs.opentmpfs().then()...

  ###*
  @static
  @method
    Open a sketch
  @param {AsyncFs} dirFs
    File system object at the sketch directory
  @return {Promise}
    Promise object
  @return {Sketch} return.PromiseValue
    The instance of sketch
  ###
  @open: (dirFs) ->
    dirFs.readFile(SKETCH_CONFIG, SKETCH_ENCODING).then((data) =>
      obj = @_migrateAtOpen(JSON.parse(data))
      return Sketch.parseJSON(obj)
    ).then((sketch) =>
      sketch._dirFs = dirFs
      return sketch
    ).catch(=>
      return I18n.rejectPromise("Invalid_sketch")
    )

  ###*
  @method
    Save sketch
  @param {AsyncFs} [newDirFs]
    File system object to store sketch
  @return {Promise}
    Promise object
  ###
  save: (newDirFs) ->
    if newDirFs?
      # Update properties
      oldDirFs = @_dirFs
      @_dirFs = newDirFs
    return @_items.reduce(
      # Save all files in sketch
      (promise, item) =>
        return item.editor.save() if item.editor?
        return unless newDirFs?
        # Relocate file
        return oldDirFs.readFile(item.path).then((data) =>
          return newDirFs.writeFile(item.path, data)
        )
      Promise.resolve()
    ).then(=>
      # Save sketch settings
      @_rubicVersion = App.version
      return newDirFs.writeFile(SKETCH_CONFIG, JSON.stringify(this), SKETCH_ENCODING)
    ).then(=>
      # Successfully saved
      @_modified = false
      newDirFs = null
      return  # Last PromiseValue
    ).finally(=>
      # Revert properties if failed
      @_dirFs = oldDirFs if newDirFs?
      return
    ) # return @_items.reduce().then()...

  ###*
  @method
    Get item in sketch
  @param {string} path
    Path of item
  @return {SketchItem/null}
    Item
  ###
  getItem: (path) ->
    return item for item in @_items when item.path == path
    return null

  ###*
  @method
    Add item to sketch
  @param {SketchItem} item
    Item to add
  @return {boolean}
    Result (true=success, false=already_exists)
  ###
  addItem: (item) ->
    return false if @getItem(item.path)?
    item.setSketch(this)
    @_items.push(item)
    @_setModified()
    return true

  ###*
  @method
    Remove item from sketch
  @param {SketchItem/string} item
    Item or path to remove
  @return {boolean}
    Result (true=success, false=not_fond)
  ###
  removeItem: (item) ->
    item = item.path unless typeof(item) == "string"
    for value, index in @_items
      if value.path == item
        @_items.splice(index, 1)
        @_setModified()
        return true
    return false

  ###*
  @method
    Setup items
  @return {undefined}
  ###
  setupItems: ->
    index = 0
    while index < @_items.length
      item = @_items[index++]
      sources = item.generatedFrom
      if sources.length > 0
        exists = 0
        ++exists for src in sources when @_items.find((i) -> i.path == src)?
        @_items.splice(--index, 1) if exists == 0
    return

  #--------------------------------------------------------------------------------
  # Protected methods
  #

  ###*
  @protected
  @method constructor
    Constructor of Sketch class
  @param {Object} obj
    JSON object
  ###
  constructor: (obj) ->
    super(obj)
    @_rubicVersion = "#{obj?.rubicVersion || ""}"
    @_items = (SketchItem.parseJSON(item) for item in (obj?.items or []))
    @_bootItem = "#{obj?.bootItem || ""}"
    @_board = Board.parseJSON(obj.board) if obj?.board?
    @_setModifiedCaller = (=> @_setModified)
    return

  ###*
  @protected
  @inheritdoc JSONable#toJSON
  ###
  toJSON: ->
    return super().extends({
      rubicVersion: @_rubicVersion
      items: @_items
      bootItem: @_bootItem
      board: @_board
    })

  #--------------------------------------------------------------------------------
  # Private methods
  #

  ###*
  @private
  @method
    Set modified flag
  @return {undefined}
  ###
  _setModified: ->
    return if @_modified
    @_modified = true
    @onChange.dispatchEvent(this)
    return

  ###*
  @private
  @method
    Execute version migration
  @param {Object} src
    Source JSON object
  @return {Object}
    Migrated JSON object
  ###
  @_migrateAtOpen: (src) ->
    switch src.rubicVersion
      when undefined
        # Migration from 0.2.x
        return {
          rubicVersion: src.sketch.rubicVersion
          items: [
            new SketchItem({path: "main.rb", transfer: false})
            new SketchItem({path: "main.mrb", generatedFrom: ["main.rb"], transfer: true})
          ]
          bootItem: "main.mrb"
          board: {
            __class__: src.sketch.board.class
          }
        }
      else
        # No migration needed from >= 0.9.x
        return src

module.exports = Sketch

# Post dependencies
EventTarget = require("./eventtarget")
I18n = require("./i18n")
AsyncFs = require("./asyncfs")
App = require("./app")
Board = require("./board")
SketchItem = require("./sketchitem")
