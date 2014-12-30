chrome.app.runtime.onLaunched.addListener ->
  chrome.app.window.create 'window.html', {
    'bounds': { 'width': 640, 'height': 480 }
  }
