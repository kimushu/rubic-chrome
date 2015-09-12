chrome.app.runtime.onLaunched.addListener(->
  chrome.app.window.create(
    "win_main.html",
    {
      id: "main",
      innerBounds: {
        width: 640, height: 480,
        minWidth: 480,
      },
    }
  ) # chrome.app.window.create
)
