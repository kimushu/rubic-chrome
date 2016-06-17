do ->
  global.JSZip = require("jszip")

do ->
  API_TEST = "http://#{window.location.host}/api"  # FOR DEBUGGING
  github = require("github-api")
  if API_TEST?
    console.warn("GitHub API will be substituted by #{API_TEST}")
    GitHub_Dummy = (args...) ->
      github.apply(this, args)
      @__apiBase = API_TEST
    GitHub_Dummy:: = github::
    global.GitHub = GitHub_Dummy
  else
    global.GitHub = github
