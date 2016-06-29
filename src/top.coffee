Function::property = (prop, desc) ->
  Object.defineProperty(@prototype, prop, desc)

Function::classProperty = (prop, desc) ->
  Object.defineProperty(@, prop, desc)

require("./es6compat")
require("./es7compat")

MainController = require("./maincontroller")
MainController.instance.activate()

# List of boards
require("./peridotboard")
require("./wakayamarbboard")
require("./grcitrusboard")
require("./sketch")

