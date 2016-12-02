"use strict"
Builder = require("builder/builder")
I18n = require("util/i18n")
require("util/primitive")

###*
@class ES5Builder
  Builder for ECMAScript5 (Model)
@extends Builder
###
module.exports = class ES5Builder extends Builder
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
  @classProperty("friendlyName", value: new I18n("JavaScript (ES5)"))

  ###*
  @static
  @inheritdoc Builder#template
  ###
  @classProperty("template", value: Object.freeze({
    suffix: "js"
    content: new I18n("// Write your code here\n")
  }))

  ###*
  @static
  @inheritdoc Builder#configurations
  ###
  @classProperty("configurations", value: Object.freeze({
  }))

  #--------------------------------------------------------------------------------
  # Private variables / constants
  #

  JS_FILETYPE = new I18n("JavaScript (ES5)")
  JS_PATTERN  = /^(.+)\.js$/i
  JS_ENCODING = "utf8"

  #--------------------------------------------------------------------------------
  # Public methods
  #

  ###*
  @static
  @inheritdoc Builder#supports
  ###
  @supports: (name) ->
    return JS_PATTERN.test(name)

  ###*
  @inheritdoc Builder#setup
  ###
  setup: ->
    js = @sketchItem
    baseName = js.path.match(JS_PATTERN)?[1]
    return Promise.reject(Error("Not supported")) unless baseName?
    js.builder = this
    js.fileType = JS_FILETYPE
    return Promise.resolve()

  ###*
  @inheritdoc Builder#build
  ###
  build: ->
    js = @sketchItem
    baseName = js.path.match(JS_PATTERN)?[1]
    return Promise.reject(Error("Not supported")) unless baseName?
    return Promise.resolve()

# Post dependencies
# (none)
