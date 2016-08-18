chrome.app.runtime.onLaunched.addListener((launchData) =>
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
      github_base: null
    })
  ).then((values) =>
    options = {
      bounds: {width: values.window_width, height: values.window_height}
    }
    chrome.app.window.create("window.html", options, (appWindow) =>
      boundsSaveTimer = null
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
        win.document.body.style.zoom = (values.zoom_ratio / 10)

        # # Set GitHub API base URL
        # base = values.github_base
        # win.Libs.GitHubFactory.apiBase = base
        # win.console.warn("GitHub API will be substituted by #{base}") if base?
      )
      return
    )
  )
)
