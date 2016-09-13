do ->
  global.localStorage = undefined
  global.Libs or= {}

  global.Libs.CoffeeScript = require("coffee-script")

  global.Libs.JsYaml = require("js-yaml")

  global.Libs.JsZip = require("jszip")

  # global.Libs.Canarium = require("canarium")

