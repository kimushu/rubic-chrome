chrome.app.runtime.onLaunched.addListener(=>
  Preferences = require("./preferences")

  Promise.resolve(
  ).then(=>
    return Preferences.get({reset_all: false})
  ).then((values) =>
    return unless values.reset_all
    console.warn("Resetting all preferences")
    return Preferences.clear()
  ).then(=>
    return Preferences.initCache()
  ).then(=>
    return Preferences.get({
      window_width: 640
      window_height: 480
      zoom_ratio: 10
    })
  ).then((values) =>
    options = {
      bounds: {width: values.window_width, height: values.window_height}
    }
    chrome.app.window.create("window.html", options, (appWindow) =>
      appWindow.onClosed.addListener(=>
        bounds = appWindow.innerBounds
        Preferences.set({
          window_width: bounds.width
          window_height: bounds.height
        })
      )
      appWindow.contentWindow.addEventListener("load", =>
        appWindow.contentWindow.document.body.style.zoom = (values.zoom_ratio / 10)
      )
      return
    )
  )
)
