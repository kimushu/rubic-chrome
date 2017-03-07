"use strict"
#================================================================
# Renderer-process entry
#================================================================

i18n = require("i18n")
path = require("path")
handlebars = require("handlebars")
AppDelegate = require("./app-delegate")
delay = require("delay")
WindowController = require("./controller/window-controller")

global.rubic = {}

# Print version information
console.info(window.navigator.userAgent)

loading = new Promise((resolve) => $(=> resolve()))
splashDelay = delay(1000)

Promise.resolve(
).then(=>
  # Create delegate
  return AppDelegate.open()
).then(=>
  # Wait for finish loading
  return loading
).then(=>
  # Load settings
  return global.rubic.settings.get({locale: window.navigator.language})
).then(({locale}) =>
  # Translate DOM elements
  console.log("Translating: #{locale}")
  i18n.configure(
    directory: path.join(__dirname, "..", "..", "locales")
    fallbacks:
      ja: "en"
    autoReload: false
    updateFiles: false
    logWarnFn: (msg) =>
      console.warn("i18n:", msg)
    logErrorFn: (msg) =>
      console.error("i18n:", msg)
  )
  i18n.setLocale(locale)
  handlebars.registerHelper("t", (str) => i18n.__(str))
  body = $("body")
  body.html(handlebars.compile(body.html()))
  global.rubic.send("translation-complete")
).then(splashDelay).then(=>
  # Activate first controller
  WindowController.launch()
  $("body").removeClass("loading")
)
