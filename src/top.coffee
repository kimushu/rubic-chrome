Function::property = (prop, desc) ->
  Object.defineProperty(@prototype, prop, desc)

Function::classProperty = (prop, desc) ->
  Object.defineProperty(@, prop, desc)

require("./es6compat")
require("./es7compat")
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

require("./sketch")

