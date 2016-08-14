require("./primitive")

# require("./es6compat")  # Chrome supports ES6!
require("./es7compat")
require("./bbjscompat")
require("./bootbox-promise")
require("./windowcontroller")

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

