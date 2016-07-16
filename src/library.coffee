do ->
  global.Libs or= {}
  global.Libs.JsZip = require("jszip")
  global.Libs.CoffeeScript = require("coffee-script")
  # global.Libs.Canarium = require("canarium")

do ->
  API_TEST = "http://#{window.location.host}/api"  # FOR DEBUGGING
  github = require("github-api")
  if API_TEST?
    console.warn("GitHub API will be substituted by #{API_TEST}")
    github_dummy = (args...) ->
      github.apply(this, args)
      @__apiBase = API_TEST
    github_dummy:: = github::
    global.Libs.GitHub = github_dummy
  else
    global.Libs.GitHub = github
