{app, BrowserWindow} = require("electron")
path = require("path")
url = require("url")
settings = require("electron-settings")

DEFAULT_WIDTH   = 640
DEFAULT_HEIGHT  = 480
MINIMUM_WIDTH   = 560
MINIMUM_HEIGHT  = 240

win = null

createWindow = =>
  after_reset = false
  Promise.resolve(
  ).then(=>
    return settings.get("reset_all")
  ).then((reset_all = false) =>
    return unless reset_all
    after_reset = true
    console.warn("Resetting all preferences")
    return settings.clear()
  ).then(=>
    return settings.get("window")
  ).then((values = {}) =>
    values.bounds ?= {}
    values.bounds.width ?= DEFAULT_WIDTH
    values.bounds.height ?= DEFAULT_HEIGHT
    values.zoom_ratio_x10 ?= 10

    win = new BrowserWindow(
      width: values.bounds.width
      height: values.bounds.height
      useContentSize: true
      minWidth: MINIMUM_WIDTH * values.zoom_ratio_x10 / 10
      minHeight: MINIMUM_HEIGHT * values.zoom_ratio_x10 / 10
      webPreferences:
        zoomFactor: values.zoom_ratio_x10 / 10
    )

    win.on("closed", =>
      win = null
    )

    win.on("resize", =>
      {width, height} = win.getContentBounds()
      settings.set("window.bounds", {width, height})
    )

    win.setMenu(null)

    win.loadURL(url.format({
      pathname: path.join(__dirname, "..", "dist", "window.html"),
      protocol: "file:",
      slashes: true
    }))

    win.webContents.openDevTools()

    console.log("locale: #{app.getLocale()}")
  )

app.on("ready", createWindow)

app.on("window-all-closed", =>
  app.quit() unless process.platform == "darwin"
)

app.on("activate", =>
  createWindow() unless win
)

