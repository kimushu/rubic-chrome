chrome.app.runtime.onLaunched.addListener(=>
  Preferences = require("./preferences")

  Preferences.get({init_cache: false}).then((values) =>
    return unless values.reset?
    return Preferences.clear()
  ).then(=>
    return Preferences.initCache()
  ).then(=>
    return Preferences.get({window_width: 640, window_height: 480})
  ).then((values) =>
    options = {
      bounds: {width: values.window_width, height: values.window_height}
    }
    chrome.app.window.create("window.html", options, (appWindow) =>
      return
    )
  )
)
