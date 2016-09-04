chrome.app.runtime.onLaunched.addListener((launchData) =>
  Preferences = require("app/preferences")

  DEFAULT_WIDTH   = 640
  DEFAULT_HEIGHT  = 480
  MINIMUM_WIDTH   = 560
  MINIMUM_HEIGHT  = 240

  reset_all = null

  Promise.resolve(
  ).then(=>
    return Preferences.get({reset_all: false})
  ).then((values) =>
    reset_all = !!values.reset_all
    return unless reset_all
    console.warn("Resetting all preferences")
    return Preferences.clear()
  ).then(=>
    return Preferences.initCache()
  ).then(=>
    return Preferences.get({
      window_width: DEFAULT_WIDTH
      window_height: DEFAULT_HEIGHT
      zoom_ratio_x10: 10
    })
  ).then((values) =>
    options = {
      innerBounds: {
        width: values.window_width
        height: values.window_height
        minWidth: MINIMUM_WIDTH * values.zoom_ratio_x10 / 10
        minHeight: MINIMUM_HEIGHT * values.zoom_ratio_x10 / 10
      }
    }
    chrome.app.window.create("window.html", options, (appWindow) =>
      appWindow.onBoundsChanged.addListener(=>
        bounds = appWindow.innerBounds
        Preferences.set({
          window_width: bounds.width
          window_height: bounds.height
        })
      )
      win = appWindow.contentWindow
      win.addEventListener("load", =>
        # Set initial zoom ratio
        win.document.body.style.zoom = (values.zoom_ratio_x10 / 10)
      )
      win.reset_all = true if reset_all
      return
    )
  )
)
