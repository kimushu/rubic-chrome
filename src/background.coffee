chrome.app.runtime.onLaunched.addListener(->
  chrome.app.window.create(
    "window.html",
    {
      id: "main",
      innerBounds: { width: 640, height: 480 },
    }
  ) # chrome.app.window.create
)
