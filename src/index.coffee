"use strict"
#================================================================
# Renderer-process entry
#================================================================

# Print version information
console.info(window.navigator.userAgent)

# Start IPC server for RubicWindow
require("./app/rubic-window").onRendererStart()

$(=>
)
