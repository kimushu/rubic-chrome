"use strict"
# Pre dependencies
Engine = require("engine/engine")
require("util/primitive")

###*
@class JavaScriptEngine
  Script execution engine for JavaScript (Model)
@extends Engine
###
module.exports = class JavaScriptEngine extends Engine
  null

  #--------------------------------------------------------------------------------
  # Public properties
  #

  ###*
  @inheritdoc Engine#languageName
  ###
  @property("languageName", get: -> "JavaScript/CoffeeScript")

  ###*
  @inheritdoc Engine#fileHandlers
  ###
  @property("fileHandlers", get: -> @_fileHandlers or= [
    new FileHandler(this, "js",
      description: new I18n("JavaScript") # TODO: how to distinguish ES6 or CommonJS?
      template: new I18n("\"use strict\";\n")
    )
    new FileHandler(this, "coffee",
      description: new I18n("CoffeeScript")
      template: new I18n("\"use strict\"\n")
      hasCompilerOptions: true
    )
  ])

  #--------------------------------------------------------------------------------
  # Private variables / constants
  #

  JS_SUFFIX         = ".js"
  COFFEE_SUFFIX_RE  = /\.coffee$/i
  COFFEE_ENCODING   = "utf8"

  #--------------------------------------------------------------------------------
  # Public methods
  #

  ###*
  @inheritdoc Engine#setup
  ###
  setup: (sketch, item) ->
    src_path = item.path
    js_path = src_path.replace(COFFEE_SUFFIX_RE, JS_SUFFIX)
    if js_path == src_path
      # No compilation needed
      item.transfered = true
      return Promise.resolve()

    # coffee->js compile
    js = new SketchItem({path: js_path})
    js.addGenerator(this)
    js.transfered = true
    return Promise.resolve([js])

  ###*
  @inheritdoc Engine#build
  ###
  build: (sketch, item) ->
    src_path = item.path
    js_path = src_path.replace(COFFEE_SUFFIX_RE, JS_SUFFIX)
    if js_path == src_path
      # No compilation needed
      return Promise.resolve()

    # coffee->js compile
    return Promise.resolve(
    ).then(=>
      return sketch.dirFs.readFile(src_path, COFFEE_ENCODING)
    ).then((data) =>
      return global.Libs.coffeescript.compile(data, {bare: true})
    ).then((data) =>
      return sketch.dirFs.writeFile(js_path, data, COFFEE_ENCODING)
    ).then(=>
      return  # Last PromiseValue
    ) # return Promise.resolve().then()...

# Post dependencies
FileHandler = require("engine/filehandler")
SketchItem = require("sketch/sketchitem")
