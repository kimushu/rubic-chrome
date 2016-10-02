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

  @_popupMessage: (ntype, etype, icon, message, title, dir = "ne", settings = {}) ->
    this[etype]("Popup {message: %o, title: %o}", message, title)
    return new Notifier({
      icon: if icon? then "glyphicon glyphicon-#{icon}-sign" else undefined
      title: title
      message: message
    }, $.extend({
      type: ntype
      allow_dismiss: true
      placement: {
        from: if dir.includes("s") then "bottom" else "top"
        align: if dir.includes("w") then "left" else (if dir.includes("e") then "right" else "center")
      }
      z_index: 990
      delay: 2000
      offset: {x: 20, y: 50}
      showProgressbar: true
    }, settings)).show()

  @popupSuccess: @_popupMessage.bind(this, "success", "log", null)
  @popupInfo:    @_popupMessage.bind(this, "info", "info", "info")
  @popupWarning: @_popupMessage.bind(this, "warning", "warn", "warning")
  @popupError:   @_popupMessage.bind(this, "danger", "error", "warning")

  ###*
  @static
  @method
    Show confirmation before danger operation
    "Yes" button is red(danger), "No" button is green(safe)
  @param {Object} options
    Options
  @param {string} [options.rawMessage]
    Raw message (Skip I18n translation)
  @param {string} [options.rawTitle]
    Raw title (Skip I18n translation)
  @param {string} [options.rawYes]
    Raw yes button text (Skip I18n translation)
  @param {string} [options.rawNo]
    Raw no button text (Skip I18n translation)
  @param {string} [options.message]
    Message (Translated by I18n.translateText)
  @param {string} [options.title]
    Title (Translated by I18n.translateText)
  @param {string} [options.yes="yes"]
    Yes button text (Translated by I18n.translateText)
  @param {string} [options.no="no"]
    No button text (Translated by I18n.translateText)
  @return {Promise}
    Promise object
  @return {"yes"/"no"}
    Selection by user
  ###
  @safeConfirm_yes_no: (options) ->
    return global.bootbox.dialog_p(
      title: options.rawTitle or I18n.translateText(options.title)
      message: options.rawMessage or I18n.translateText(options.message)
      closeButton: false
      buttons: {
        yes: {
          label: options.rawYes or I18n.translateText(options.yes or "{Yes}")
          className: "btn-danger"
        }
        cancel: {
          label: options.rawNo or I18n.translateText(options.no or "{No}")
          className: "btn-success"
        }
      }
    ) # return global.bootbox.dialog_p()

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
I18n = require("util/i18n")
