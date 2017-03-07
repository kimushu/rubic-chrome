"use strict"
require("../../util/primitive")
path = require("path")
RubicSettings = require("./rubic-settings")
RubicWindow = require("./rubic-window")
{app, ipcMain} = require("electron")

###*
Application top class

@class RubicApplication
###
module.exports =
class RubicApplication

  constructor: (options) ->
    console.log("new RubicApplication()")
    @_verbosity = 0
    @_settings = new RubicSettings(options)
    return

  ###*
  Settings class instance

  @property {RubicSettings} settings
  @readOnly
  ###
  @getter "settings", -> @_settings

  ###*
  Current sketch (Read-only. Use setSketch() to change)

  @property {Sketch} sketch
  @readOnly
  ###
  @getter "sketch", -> @_sketch

  ###*
  Version of Rubic

  @property {string} version
  @readOnly
  ###
  @getter "version", ->
    unless @_version?
      info = require(path.join(__dirname, "..", "..", "package.json"))
      @_version = info.version
    return @_version

  ###*
  Create a RubicApplication instance

  @static
  @method open
  @param {Object} options
    Launch options
  @return {Promise|RubicApplication}
    Promise object with instance
  ###
  @open: (options) ->
    console.log("RubicApplication.open(options) :", options)
    return new RubicApplication(options)._initialize(options)

  ###*
  Initialize instance

  @private
  @method _initialize
  @param {Object} options
    Launch options
  @return {Promise|RubicApplication}
    Promise object with instance
  ###
  _initialize: (options) ->
    console.log("RubicApplication#_initialize()")

    # Register RubicApplication instance to global
    global.rubic = this

    # Initialize internal properties
    @_sketch = null
    @_window = new RubicWindow(options)

    @_delegateReady = new Promise((resolve) =>
      ipcMain.on("delegate-ready", (event) =>
        console.log("[RubicApplication] received delegate-ready message")
        resolve()
      )
    )

    # Register Electron event handlers
    app.on("ready", =>
      console.log("[RubicApplication] ready")
      notifyReset = false
      return Promise.resolve(
      ).then(=>
        # Reset preferences if reset_all == true
        return @_settings.get({reset_all: false}).then(({reset_all}) =>
          return unless reset_all
          notifyReset = true
          console.log("[RubicApplication] cleared all preferences")
          return @_settings.clear()
        )
      ).then(=>
        return @_window.open()
      ).then(=>
        return @_delegateReady
      ).then(=>
        @log(0, "Established link between main and renderer process")
        return unless notifyReset
        @warn(0, "All preferences has been reset")
        return
      ).catch((error) =>
        @abort(error)
      )
    )
    app.on("window-all-closed", =>
      console.log("[RubicApplication] window-all-closed")
      app.quit() unless process.platform == "darwin"
    )
    app.on("activate", =>
      console.log("[RubicApplication] activate")
      @_window.open()
    )

    console.log("[RubicApplication] waiting for Electron ready")

    return @_delegateReady.then(=>
      return this # Last PromiseValue
    )

  ###*
  Abort application with error message

  @method abort
  @param {Error} [error]
    Error object
  ###
  abort: (error) ->
    console.error(error) if error?
    process.exitCode = 1
    app.quit()
    return

  ###*
  Debug verbosity level

  @property {number} verbosity
  ###
  @property "verbosity",
    get: -> @_verbosity
    set: (v) -> @_verbosity = parseInt(v)

  ###*
  Output debug message (level=log)

  @method log
  @param {number} [verbosity=0]
    Verbosity level
  @param {string|function} msg
    Message string or function to generate message
  @param {Object} ...params
    Parameters for substituting by sprintf
  ###
  log: (verbosity, msg, params...) ->
    return @_window?.debugPrint("log", msg, params...) if verbosity <= @_verbosity

  ###*
  Output debug message (level=info)

  @method info
  @param {number} [verbosity=0]
    Verbosity level
  @param {string|function} msg
    Message string or function to generate message
  @param {Object} ...params
    Parameters for substituting by sprintf
  ###
  info: (verbosity, msg, params...) ->
    return @_window?.debugPrint("info", msg, params...) if verbosity <= @_verbosity

  ###*
  Output debug message (level=warning)

  @method warn
  @param {number} [verbosity=0]
    Verbosity level
  @param {string|function} msg
    Message string or function to generate message
  @param {Object} ...params
    Parameters for substituting by sprintf
  ###
  warn: (verbosity, msg, params...) ->
    return @_window?.debugPrint("warn", msg, params...) if verbosity <= @_verbosity

  ###*
  Output debug message (level=error)

  @method error
  @param {number} [verbosity=0]
    Verbosity level
  @param {string|function} msg
    Message string or function to generate message
  @param {Object} ...params
    Parameters for substituting by sprintf
  ###
  error: (verbosity, msg, params...) ->
    return @_window?.debugPrint("error", msg, params...) if verbosity <= @_verbosity

  #-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/

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

  #@info("Rubic/%s %s", @version, window?.navigator.userAgent)

  # Object disclosure for debugging
  #@log("Application: %o", App)

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
#Preferences = require("app/preferences")
#Notifier = require("ui/notifier")
#I18n = require("util/i18n")
