"use strict"
# Pre dependencies
Builder = require("builder/builder")
I18n = require("util/i18n")
require("util/primitive")

###*
@class MrubyBuilder
  Builder for mruby (Model)
@extends Builder
###
module.exports = class MrubyBuidler extends Builder
  Builder.jsonable(this)

  #--------------------------------------------------------------------------------
  # Public properties
  #

  ###*
  @static
  @property {I18n} friendlyName
    Name of this builder
  @readonly
  ###
  @classProperty("friendlyName", value: new I18n({
    en: "mruby compiler"
    ja: "mruby コンパイラ"
  }))

  ###*
  @property {boolean} debugInfo
    Enable debugging information (-g)
  ###
  @property("debugInfo",
    get: -> @_debugInfo
    set: (v) -> @_debugInfo = !!v
  )

  ###*
  @property {boolean} enableDump
    Enable verbose dump (-v)
  ###
  @property("enableDump",
    get: -> @_enableDump,
    set: (v) -> @_enableDump = !!v
  )

  ###*
  @property {string} compileOptions
    Other compile options
  ###
  @property("compileOptions",
    get: -> @_compileOptions
    set: (v) -> @_compileOptions.toString() or ""
  )

  #--------------------------------------------------------------------------------
  # Private variables / constants
  #

  RB_FILETYPE = new I18n({
    en: "Ruby script"
    ja: "Ruby スクリプト"
  })
  RB_PATTERN = /^(.+)\.rb$/i
  RB_ENCODING = "utf8"

  MRB_FILETYPE = new I18n({
    en: "mruby executable"
    ja: "mruby 実行ファイル"
  })

  DUMP_FILETYPE = new I18n({
    en: "mruby compiler dump output"
    ja: "mruby コンパイラダンプ出力"
  })

  #--------------------------------------------------------------------------------
  # Public methods
  #

  ###*
  @static
  @inheritdoc Builder#supports
  ###
  @supports: (name) ->
    return RB_PATTERN.test(name)

  ###*
  @inheritdoc Builder#setup
  ###
  setup: ->
    rb = @sketchItem
    baseName = rb.path.match(RB_PATTERN)?[1]
    return Promise.reject(Error("Not supported")) unless baseName?
    rb.builder = this
    rb.fileType = RB_FILETYPE
    mrb = rb.sketch.getItem("#{baseName}.mrb", true)
    mrb.builder = null
    mrb.fileType = MRB_FILETYPE
    mrb.source = rb
    if @_enableDump
      dump = rb.sketch.getItem("#{baseName}.dump", true)
      dump.builder = null
      dump.fileType = DUMP_FILETYPE
      dump.source = rb
    else
      rb.sketch.removeItem("#{baseName}.dump")
    return Promise.resolve()

  ###*
  @inheritdoc Builder#build
  ###
  build: ->
    rb = @sketchItem
    baseName = rb.path.match(RB_PATTERN)?[1]
    return Promise.reject(Error("Not supported")) unless baseName?
    mrb = rb.sketch.getItem("#{baseName}.mrb")
    return Promise.reject(Error("Setup required")) unless mrb?
    dump = rb.sketch.getItem("#{baseName}.dump") if @_enableDump
    fileName = baseName.split("/").pop()
    mrbc = new global.Libs.mrbc()
    return Promise.resolve(
    ).then(=>
      return mrbc.setup()
    ).then(=>
      return rb.readContent({encoding: RB_ENCODING})
    ).then((data) =>
      return mrbc.writeFile("/#{fileName}.rb", data, {encoding: RB_ENCODING})
    ).then(=>
      opts = ["-o/#{fileName}.mrb"]
      opts.push("-g") if @_debugInfo
      opts.push("-v") if @_enableDump
      opts.push("/#{fileName}.rb")
      opts.push(@_compileOptions)
      return mrbc.run(opts...)
    ).then((status) =>
      return Promise.reject(
        @_convertError(String.fromCharCode.apply(null, mrbc.readStderr()))
      ) unless status == 0
      return mrbc.readFile("/#{fileName}.mrb")
    ).then((data) =>
      return mrb.writeContent(data)
    ).then(=>
      return dump?.writeContent(mrbc.readStdout())
    ).then(=>
      return  # Last PromiseValue
    ) # return Promise.resolve().then()...

  ###*
  @method constructor
    Constructor of MrubyBuilder class
  @param {Object} obj
    JSON object
  @param {SketchItem} _sketchItem
    SketchItem instance associated to this builder
  ###
  constructor: (obj = {}, sketchItem) ->
    super(obj, sketchItem)
    @_debugInfo = !!obj.debugInfo
    @_enableDump = !!obj.enableDump
    @_compileOptions = obj.compileOptions?.toString() or ""
    return

  ###*
  @inheritdoc JSONable#toJSON
  ###
  toJSON: ->
    return super().extends({
      debugInfo: @_debugInfo
      enableDump: @_enableDump
      compileOptions: @_compileOptions
    })

  #--------------------------------------------------------------------------------
  # Private methods
  #

  ###*
  @private
  @method
    Convert stderr message to Error object
  @param {string} text
    stderr output
  @return {Error}
    Error object
  ###
  _convertError: (text) ->
    e = null
    text.match(/^\/([^:]+):(\d+):(\d+):\s+([^,]+),\s+(.*)$/, (match, file, line, col, type, msg) ->
      switch(type)
        when "syntax error"
          e = new SyntaxError(msg)
      return unless e?
      e.fileName = file
      e.lineNumber = line
      e.columnNumber = col
      e.toString = ->
        return "#{@fileName}:#{@lineNumber}:#{@columnNumber}: #{@constructor.name}: #{@message}"
    )
    return e or new Error(text)

# Post dependencies
# (none)
