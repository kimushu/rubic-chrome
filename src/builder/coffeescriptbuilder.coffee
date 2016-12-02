"use strict"
# Pre dependencies
Builder = require("builder/builder")
I18n = require("util/i18n")
require("util/primitive")

###*
@class CoffeeScriptBuilder
  Builder for CoffeeScript (Model)
@extends Builder
###
module.exports = class CoffeeScriptBuilder extends Builder
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
  @classProperty("friendlyName", value: new I18n("CoffeeScript"))

  ###*
  @static
  @inheritdoc Builder#template
  ###
  @classProperty("template", value: Object.freeze({
    suffix: "coffee"
    content: new I18n("#!coffee\n")
  }))

  ###*
  @static
  @inheritdoc Builder#configurations
  ###
  @classProperty("configurations", value: Object.freeze({
    bare: {
      type: "boolean"
      description: new I18n(
        en: "Compile without a top-level function wrapper"
        ja: "最上位の関数ラッパを省略する (-b)"
      )
    }
  }))

  ###*
  @property {boolean} bare
    Enable bare JS generation
  ###
  @property("bare",
    get: -> @_bare
    set: (v) -> @_bare = !!v
  )

  #--------------------------------------------------------------------------------
  # Private variables / constants
  #

  COFFEE_FILETYPE = new I18n("CoffeeScript")
  COFFEE_PATTERN  = /^(.+)\.coffee$/i
  COFFEE_ENCODING = "utf8"

  JS_FILETYPE = new I18n("JavaScript (ES5)")
  JS_ENCODING = "utf8"

  #--------------------------------------------------------------------------------
  # Public methods
  #

  ###*
  @static
  @inheritdoc Builder#supports
  ###
  @supports: (name) ->
    return COFFEE_PATTERN.test(name)

  ###*
  @inheritdoc Builder#setup
  ###
  setup: ->
    coffee = @sketchItem
    baseName = coffee.path.match(COFFEE_PATTERN)?[1]
    return Promise.reject(Error("Not supported")) unless baseName?
    coffee.builder = this
    coffee.fileType = COFFEE_FILETYPE
    js = coffee.sketch.getItem("#{baseName}.js", true)
    js.builder = null
    js.fileType = JS_FILETYPE
    js.source = coffee
    js.transfer = true
    return Promise.resolve()

  ###*
  @inheritdoc Builder#build
  ###
  build: ->
    coffee = @sketchItem
    baseName = coffee.path.match(COFFEE_PATTERN)?[1]
    return Promise.reject(Error("Not supported")) unless baseName?
    js = coffee.sketch.getItem("#{baseName}.js")
    return Promise.reject(Error("Setup required")) unless js?
    return Promise.resolve(
    ).then(=>
      return coffee.readContent({encoding: COFFEE_ENCODING})
    ).then((data) =>
      return global.Libs.CoffeeScript.compile(data, {
        bare: @_bare
      })
    ).then((data) =>
      return js.writeContent(data, {encoding: JS_ENCODING})
    ).then(=>
      return  # Last PromiseValue
    ) # return Promise.resolve().then()...

  ###*
  @method constructor
    Constructor of CoffeeScriptBuilder class
  @param {Object} obj
    JSON object
  @param {SketchItem} _sketchItem
    SketchItem instance associated to this builder
  ###
  constructor: (obj = {}, sketchItem) ->
    super(obj, sketchItem)
    @_bare = if obj.bare? then !!obj.bare else true
    return

  ###*
  @inheritdoc JSONable#toJSON
  ###
  toJSON: ->
    return super().extends({
      bare: @_bare
    })

# Post dependencies
# (none)
