# Pre dependencies
Engine = require("./engine")
JavaScriptEngine = require("./javascriptengine")

###*
@class DuktapeEngine
  Script execution engine for duktape (Model)
@extends Engine
###
class DuktapeEngine extends JavaScriptEngine
  Engine.jsonable(this)

  #--------------------------------------------------------------------------------
  # Public properties
  #

  @classProperty("coreName", get: -> "Duktape")

module.exports = DuktapeEngine
