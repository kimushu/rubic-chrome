"use strict"
# Pre dependencies
Engine = require("engine/engine")
JavaScriptEngine = require("engine/javascriptengine")
require("util/primitive")

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
