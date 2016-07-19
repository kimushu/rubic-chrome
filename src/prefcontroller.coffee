# Pre dependencies
WindowController = require("./windowcontroller")

###*
@class PrefController
  Controller for preference view (Controller, Singleton)
@extends Controller
###
class PrefController extends WindowController
  null
  instance = null

  #--------------------------------------------------------------------------------
  # Public properties
  #

  ###*
  @static
  @property {PrefController}
    The instance of this class
  @readonly
  ###
  @classProperty("instance", get: ->
    return instance or= new PrefController(window)
  )

  #--------------------------------------------------------------------------------
  # Protected methods
  #

  ###*
  @protected
  @inheritdoc Controller#onActivated
  ###
  onActivated: ->
    super
    @$("#config-for-testers").prop("checked", false).click((event) =>
      state = @$(event.target).prop("checked")
      @$("body")[if state then "addClass" else "removeClass"]("show-testers")
    )
    Preferences.get({
      zoom_ratio: 10
      beta_firmware: false
      log_verbosity: 0
      reset_all: false
    }).then((items) =>
      console.log(items)
      @$("#config-zoom-ratio").val("#{items.zoom_ratio}").change((event) =>
        value = parseInt(@$(event.target).val())
        Preferences.set({zoom_ratio: value})
        bounds = @appWindow.innerBounds
        curRatio = (parseFloat(window.document.body.style.zoom) or 1)
        newRatio = value / 10
        bounds.setSize(
          bounds.width / curRatio * newRatio
          bounds.height / curRatio * newRatio
        )
        window.document.body.style.zoom = newRatio
      )
      @$("#config-beta-firmware").val("#{items.beta_firmware}").change((event) =>
        value = (@$(event.target).val() != "false")
        Preferences.set({beta_firmware: value})
      )
      @$("#config-log-verbosity").val("#{items.log_verbosity}").change((event) =>
        value = parseInt(@$(event.target).val())
        Preferences.set({log_verbosity: value})
      )
      @$("#config-reset-all").val("#{items.reset_all}").change((event) =>
        value = (@$(event.target).val() != "false")
        Preferences.set({reset_all: value})
        App.warn("All preferences will be cleared at the next boot!") if value
      )
    )
    @$("body").addClass("controller-pref")
    return

  ###*
  @protected
  @inheritdoc Controller#onDeactivated
  ###
  onDeactivated: ->
    @$("body").removeClass("controller-pref show-testers")
    @$("#config-for-testers").unbind("click")
    @$("#config-zoom-ratio").unbind("change")
    @$("#config-beta-firmware").unbind("change")
    @$("#config-log-verbosity").unbind("change")
    @$("#config-reset-all").unbind("change")
    super
    return

  #--------------------------------------------------------------------------------
  # Private methods
  #

  ###*
  @private
  @method constructor
    Constructor of PrefController class
  @param {Window} window
    window object
  ###
  constructor: (window) ->
    super(window)
    return

module.exports = PrefController

# Post dependencies
I18n = require("./i18n")
App = require("./app")
Preferences = require("./preferences")
