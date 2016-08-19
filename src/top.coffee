###
  Top module for Rubic (for Chrome App)
###

# Compatibility modules
require("compat/es7compat")
require("compat/bbjscompat")

# UI helpers
require("ui/bootbox-promise")

$(->
  require("app/preferences").initCache().then(->
    # WindowController should be loaded before MainController
    # to solve circular dependency
    require("controller/windowcontroller")

    # Load main controller
    require("controller/maincontroller").instance.activate()

    # Boards
    require("board/peridotboard")
    require("board/wakayamarbboard")
    require("board/grcitrusboard")

    # Engines
    require("engine/mrubyengine")
    require("engine/duktapeengine")
    require("engine/luaengine")
    require("engine/micropythonengine")

    # Editors
    require("editor/rubyeditor")
    require("editor/mrbviewer")
    require("editor/javascripteditor")
    require("editor/coffeescripteditor")
    require("editor/luaeditor")
    require("editor/pythoneditor")
    require("editor/yamleditor")
  )
)

