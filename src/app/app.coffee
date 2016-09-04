"use strict"
# Pre dependencies
require("util/primitive")

###*
@class App
  Application top class (Not instanciatable)
###
module.exports = class App
  null

  # Version emulation for browser view
  VER_EMULATION = "0.9.0"

  # Conversion from version string to integer
  v2i = (v) ->
    [p1, p2, p3, p4] = v.split(".", 4).map((p) -> parseInt(p) & 0xffff)
    return (p1 << 48) | (p2 << 32) | (p3 << 16) | (p4 << 0)

  ###*
  @static
  @property {Sketch}
    Current sketch
  ###
  @classProperty("sketch",
    get: -> @_sketch
    set: (v) ->
      @_sketch = v
      t = "#{v.friendlyName} - " if v?
      window.document.title = "#{t or ""}Rubic"
      return
  )

  ###*
  @static
  @property {string}
    Version string for Rubic
  @readonly
  ###
  @classProperty("version", value: chrome?.runtime?.getManifest?()["version"] or VER_EMULATION)

  for type in ["log", "info", "warn", "error"]
    Object.defineProperty(
      (@[type] = console[type].bind(console))
      "verbose"
      get: ->
        return this if Preferences.logVerbosity >= 1
        return (-> return)
    )

  @info("Rubic/%s %s", @version, window?.navigator.userAgent)

  # Object disclosure for debugging
  @log("Application: %o", App)

  @_popupMessage: (ntype, etype, icon, message, title) ->
    this[etype]("Popup message: #{JSON.stringify({message: message, title: title})}")
    return new Notifier({
      icon: if icon? then "glyphicon glyphicon-#{icon}-sign" else undefined
      title: title
      message: message
    }, {
      type: ntype
      allow_dismiss: true
      placement: {from: "bottom", align: "center"}
      delay: 2
      offset: {x: 20, y: 50}
      showProgressbar: true
    }).show()

  @popupSuccess: @_popupMessage.bind(this, "success", "log", null)
  @popupInfo:    @_popupMessage.bind(this, "info", "info", "info")
  @popupWarning: @_popupMessage.bind(this, "warning", "warn", "warning")
  @popupError:   @_popupMessage.bind(this, "danger", "error", "warning")

  ###*
  @static
  @method
    Check if current version matches an version-check expression
  @param {string} versionExpr
    Expression for version check
  @return {boolean}
    Result of version check
  ###
  @versionCheck: (expr) ->
    return true unless expr?
    current = v2i(@version)
    for expr2 in expr.split(",")
      result = true
      for expr3 in expr.split("&")
        [operator, value] = expr3.trim().split(" ")
        target = v2i(value)
        switch operator
          when ">"  then result and= (current >  target)
          when "<"  then result and= (current <  target)
          when ">=" then result and= (current >= target)
          when "<=" then result and= (current >= target)
          when "==" then result and= (current == target)
          else result = false
        break unless result
      return true if result
    return false

# Post dependencies
Preferences = require("app/preferences")
Notifier = require("ui/notifier")
