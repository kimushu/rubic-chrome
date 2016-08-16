"use strict"
# Pre dependencies
Engine = require("./engine")
JavaScriptEngine = require("./javascriptengine")

###*
@class DuktapeEngine
  Script execution engine for duktape (Model)
@extends JavaScriptEngine
###
module.exports = class DuktapeEngine extends JavaScriptEngine
  Engine.jsonable(this)

  #--------------------------------------------------------------------------------
  # Public properties
  #

  ###*
  @inheritdoc Engine#friendlyName
  ###
  @property("friendlyName", get: -> "Duktape")

# Post dependencies
# (none)
