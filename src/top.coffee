Function::property = (prop, desc) ->
  Object.defineProperty(@prototype, prop, desc)

Function::classProperty = (prop, desc) ->
  Object.defineProperty(@, prop, desc)

window.delayedLoader = (dict) ->
  lib = {}
  fix = (name, obj) -> Object.defineProperty(lib, name, {enumerable: true, value: obj})
  dly = (name, loader) ->
    Object.defineProperty(lib, name, {
      enumerable: true
      configurable: true
      get: -> fix(name, obj = loader()); return obj
    })
  for key, value of dict
    if typeof(value) == "function"
      dly(key, value)
    else
      fix(key, value)
  return lib

require("./es6compat")
require("./es7compat")
require("./bbjscompat")
require("./bootbox-promise")

MainController = require("./maincontroller")
MainController.instance.activate()

# List of boards
require("./peridotboard")
require("./wakayamarbboard")
require("./grcitrusboard")

# List of engines
require("./mrubyengine")
require("./duktapeengine")
require("./luaengine")
require("./micropythonengine")

# List of editors
require("./rubyeditor")
require("./mrbviewer")
require("./javascripteditor")
require("./luaeditor")

require("./sketch")

