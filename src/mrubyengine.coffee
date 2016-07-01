# Pre dependencies
Engine = require("./engine")
SketchItem = null

###*
@class MrubyEngine
  Script execution engine for mruby (Model)
@extends Engine
###
class MrubyEngine extends Engine
  Engine.jsonable(this)

  #--------------------------------------------------------------------------------
  # Public properties
  #

  ###*
  @inheritdoc Engine#coreName
  ###
  @classProperty("coreName", get: -> "mruby")

  ###*
  @inheritdoc Engine#langName
  ###
  @classProperty("langName", get: -> "mruby")

  ###*
  @inheritdoc Engine#suffixes
  ###
  @classProperty("suffixes", get: -> ["rb"])

  #--------------------------------------------------------------------------------
  # Private constants
  #

  RUBY_SUFFIX_RE  = /\.rb$/i
  MRB_SUFFIX      = ".mrb"
  DUMP_SUFFIX     = ".dump"
  RUBY_ENCODING   = "utf8"

  #--------------------------------------------------------------------------------
  # Public methods
  #

  ###*
  @inheritdoc Engine#setup
  ###
  setup: (sketch, item) ->
    src_path = item.path
    mrb_path = src_path.replace(RUBY_SUFFIX_RE, MRB_SUFFIX)
    if mrb_path == src_path
      # No compilation needed
      item.transfered = true
      return Promise.resolve()

    # rb->mrb compile
    dump_path = src_path.replace(RUBY_SUFFIX_RE, DUMP_SUFFIX)
    SketchItem or= require("./sketchitem")
    items = []
    mrb = new SketchItem({path: mrb_path})
    mrb.generatedFrom = [src_path]
    mrb.transfered = true
    items.push(mrb)
    if item.compilerOptions.split(" ").includes("-v")
      # rb->mrb compile with dump
      dump = new SketchItem({path: dump_path})
      dump.generatedFrom = [src_path]
      dump.transfered = false
      items.push(dump)
    return Promise.resolve(items)

  ###*
  @inheritdoc Engine#build
  ###
  build: (sketch, item) ->
    mrbc = new global.Libs.mrbc()
    src_path = item.path
    mrb_path = src_path.replace(RUBY_SUFFIX_RE, MRB_SUFFIX)
    if mrb_path == src_path
      # No compilation needed
      return Promise.resolve()

    # rb->mrb compile
    dump_path = src_path.replace(RUBY_SUFFIX_RE, DUMP_SUFFIX)
    src_data = null
    return Promise.resolve(
    ).then(=>
      return sketch.dirFs.readFile(src_path, RUBY_ENCODING)
    ).then((data) =>
      src_data = data
      return mrbc.setup()
    ).then(=>
      return mrbc.writeFile("/#{src_path}", src_data, RUBY_ENCODING)
    ).then(=>
      return mrbc.run("-o/#{mrb_path}", "-g", (item.flags or [])...)
    ).then((status) =>
      unless status == 0
        e = @_convertError(String.fromCharCode.apply(null, mrbc.readStderr()))
        return Promise.reject(e)
      return mrbc.readFile("/#{mrb_path}")
    ).then((data) =>
      return sketch.dirFs.writeFile(mrb_path, data)
    ).then(=>
      return unless item.compilerOptions.split(" ").includes("-v")
      # rb->mrb compile with dump
      return sketch.dirFs.writeFile(dump_path, mrbc.readStdout())
    ).then(=>
      return  # Last PromiseValue
    ) # return Promise.resolve().then()

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

module.exports = MrubyEngine
