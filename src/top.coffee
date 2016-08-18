require("util/primitive")

# require("compat/es6compat")  # Chrome supports ES6!
require("compat/es7compat")
require("compat/bbjscompat")
require("bootbox-promise")
require("controller/windowcontroller")

MainController = require("controller/maincontroller")
MainController.instance.activate()

# List of boards
require("board/peridotboard")
require("board/wakayamarbboard")
require("board/grcitrusboard")

# List of engines
require("engine/mrubyengine")
require("engine/duktapeengine")
require("engine/luaengine")
require("engine/micropythonengine")

# List of editors
require("editor/rubyeditor")
require("editor/mrbviewer")
require("editor/javascripteditor")
require("editor/coffeescripteditor")
require("editor/luaeditor")
require("editor/pythoneditor")
require("editor/yamleditor")

require("sketch/sketch")

