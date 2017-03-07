"use strict"
#================================================================
# Renderer-process entry
#================================================================

i18n = require("i18n")
path = require("path")
handlebars = require("handlebars")
RubicBridge = require("./rubic-bridge")
delay = require("delay")
require("./controller/window-controller")
MainController = require("./controller/main-controller")

global.rubic = {}

# Print version information
console.info(window.navigator.userAgent)

loading = new Promise((resolve) => $(=> resolve()))
splashDelay = delay(1000)

Promise.resolve(
).then(=>
  # Make bridge between main-process
  console.log("bridge open")
  return RubicBridge.open()
).then(=>
  # Wait for finish loading
  console.log("Waiting for finish of document load")
  return loading
).then(=>
  # Load settings
  console.log("setting")
  return global.bridge.settings.get({locale: window.navigator.language})
).then(({locale}) =>
  # Translate DOM elements
  console.log("Translating: #{locale}")
  i18n.configure(
    directory: path.join(__dirname, "..", "locales")
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
  global.bridge.send("translation-complete")
).then(splashDelay).then(=>
  MainController.instance.activate()
  $("body").removeClass("loading")
)
