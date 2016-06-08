# Pre dependencies
WindowController = require("./windowcontroller")
Preferences = null

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
    Preferences or= require("./preferences")
    Preferences.get({
      beta_firmware: false
      log_verbosity: 0
      init_cache: false
    }).then((items) =>
      console.log(items)
      @$("#config-beta-firmware").val("#{items.beta_firmware}").change((event) =>
        value = (@$(event.target).val() != "false")
        Preferences.set({beta_firmware: value})
      )
      @$("#config-log-verbosity").val("#{items.log_verbosity}").change((event) =>
        value = parseInt(@$(event.target).val())
        Preferences.set({log_verbosity: value})
      )
      @$("#config-init-cache").val("#{items.init_cache}").change((event) =>
        value = (@$(event.target).val() != "false")
        Preferences.set({init_cache: value})
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
    @$("#config-beta-firmware").unbind("change")
    @$("#config-log-verbosity").unbind("change")
    @$("#config-init-cache").unbind("change")
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
