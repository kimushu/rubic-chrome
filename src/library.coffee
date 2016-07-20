do ->
  global.Libs or= {}

  global.Libs.JsZip = require("jszip")

  global.Libs.CoffeeScript = require("coffee-script")

  # global.Libs.Canarium = require("canarium")

  global.Libs.GitHubFactory = {
    GitHub: require("github-api")
    apiBase: "http://#{window.location.host}/api"
    create: (args...) ->
      instance = new @GitHub(args...)
      instance.__apiBase = @apiBase if @apiBase?
      return instance
  }

