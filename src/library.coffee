do ->
  global.localStorage = undefined
  global.Libs or= {}

  global.Libs.JsZip = require("jszip")

  global.Libs.CoffeeScript = require("coffee-script")

  # global.Libs.Canarium = require("canarium")

