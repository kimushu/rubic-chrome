###
Rubic Application launcher
###

# Rubic namespace root
window.Rubic or= {}

# Debug settings
# Rubic.DEBUG = 1

# Start controller
chrome.app.runtime.onLaunched.addListener((launchData) ->
  console.log({info: "Starting Rubic..."})
  new Rubic.MainController().start()
)
