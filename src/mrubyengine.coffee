"use strict"
# Pre dependencies
Engine = require("./engine")

###*
@class MrubyEngine
  Script execution engine for mruby (Model)
@extends Engine
###
module.exports = class MrubyEngine extends Engine
  Engine.jsonable(this)

  #--------------------------------------------------------------------------------
  # Public properties
  #

  ###*
  @inheritdoc Engine#friendlyName
  ###
  @property("friendlyName", get: -> "mruby")

  ###*
  @inheritdoc Engine#languageName
  ###
  @property("languageName", get: -> "mruby")

  ###*
  @inheritdoc Engine#fileTypes
  ###
  @property("fileTypes", get: -> [
    {
      suffix: "rb"
      name: {"en": "Ruby script", "ja": "Ruby スクリプト"}
    }
  ])

  ###*
  @property {string} version
    mruby version string
  @readonly
  ###
  @property("version", get: -> @_version)

  #--------------------------------------------------------------------------------
  # Private constants
  #

  RUBY_ENCODING   = "utf8"

  #--------------------------------------------------------------------------------
  # Public methods
  #

  ###*
  @inheritdoc Engine#setup
  ###
  setup: (sketch, item) ->
    paths = @_parseName(item.path)
    unless paths.rb
      # Not rb file
      item.transfered = true if paths.mrb
      return Promise.resolve()

    # rb->mrb compile
    items = []
    mrb = new SketchItem({path: paths.mrb})
    mrb.generatedFrom = [paths.rb]
    mrb.transfered = true
    items.push(mrb)
    if item.compilerOptions.split(" ").includes("-v")
      # rb->mrb compile with dump
      dump = new SketchItem({path: path.dump})
      dump.generatedFrom = [paths.rb]
      dump.transfered = false
      items.push(dump)
    return Promise.resolve(items)

  ###*
  @inheritdoc Engine#build
  ###
  build: (sketch, item) ->
    mrbc = new global.Libs.mrbc()
    paths = @_parseName(item.path)
    unless paths.rb
      return Promise.resolve()

    # rb->mrb compile
    src_data = null
    return Promise.resolve(
    ).then(=>
      return sketch.dirFs.readFile(paths.rb, RUBY_ENCODING)
    ).then((data) =>
      src_data = data
      return mrbc.setup()
    ).then(=>
      return mrbc.writeFile("/#{paths.rb}", paths.rb, RUBY_ENCODING)
    ).then(=>
      return mrbc.run("-o/#{paths.mrb}", "-g", (item.flags or [])...)
    ).then((status) =>
      unless status == 0
        e = @_convertError(String.fromCharCode.apply(null, mrbc.readStderr()))
        return Promise.reject(e)
      return mrbc.readFile("/#{paths.mrb}")
    ).then((data) =>
      return sketch.dirFs.writeFile(paths.mrb, data)
    ).then(=>
      return unless item.compilerOptions.split(" ").includes("-v")
      # rb->mrb compile with dump
      return sketch.dirFs.writeFile(paths.dump, mrbc.readStdout())
    ).then(=>
      return  # Last PromiseValue
    ) # return Promise.resolve().then()

  ###*
  @method constructor
    Constructor of MrubyEngine class
  @param {Object} obj
  ###
  constructor: (obj) ->
    super(obj)
    @_version = obj?.version
    return

  ###*
  @method
    Convert to JSON object
  @return {Object}
  ###
  toJSON: ->
    return super().extends({
      version: @_version
    })

  #--------------------------------------------------------------------------------
  # Private methods
  #

  ###*
  @private
  @method
    Parse file name
  @param {string} path
    File path
  @return {Object}
    Parsed paths
  @return {string} return.rb
    rb file path
  @return {string} return.mrb
    mrb file path
  @return {string} return.dump
    dump file path
  ###
  _parseName: (path) =>
    result = {path: path}
    base = path.replace(/\.rb$/i, =>
      result.rb = path
      return ""
    )
    if result.rb?
      result.mrb = base + ".mrb"
      result.dump = base + ".dump"
    else if path.match(/\.mrb$/i)
      result.mrb = path
    return result

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
SketchItem = require("./sketchitem")
