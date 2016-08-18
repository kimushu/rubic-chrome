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
  @inheritdoc Engine#suffixes
  ###
  @property("fileTypes", get: -> [
    {
      suffix: "js"
      name: "JavaScript"  # TODO: how to distinguish ES6 or CommonJS?
    },
    {
      suffix: "coffee"
      name: "CoffeeScript"
    }
  ])

  #--------------------------------------------------------------------------------
  # Private constants
  #

  COFFEE_SUFFIX_RE  = /\.coffee$/i
  JS_SUFFIX         = ".js"
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
    js.generatedFrom = [src_path]
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
SketchItem = require("sketch/sketchitem")
