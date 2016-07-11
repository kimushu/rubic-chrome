# Pre dependencies
Engine = require("./engine")

###*
@class JavaScriptEngine
  Script execution engine for JavaScript (Model)
@extends Engine
###
class JavaScriptEngine extends Engine
  null

  #--------------------------------------------------------------------------------
  # Public properties
  #

  ###*
  @inheritdoc Engine#langName
  ###
  @classProperty("langName", get: -> "JavaScript/CoffeeScript")

  ###*
  @inheritdoc Engine#suffixes
  ###
  @classProperty("suffixes", get: -> ["js", "coffee"])
  # {js: new I18n({en: "JavaScript"}),
  #  coffee: new I18n({en: "Coffee script", ja: "Coffee スクリプト"})}

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

module.exports = JavaScriptEngine

# Post dependencies
SketchItem = require("./sketchitem")
