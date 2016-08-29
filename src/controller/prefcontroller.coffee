"use strict"
# Pre dependencies
WindowController = require("controller/windowcontroller")

###*
@class PrefController
  Controller for preference view (Controller, Singleton)
@extends WindowController
###
module.exports = class PrefController extends WindowController
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
  @inheritdoc Controller#activate
  ###
  activate: ->
    return super(
    ).then(=>
      @$("#config-for-testers").prop("checked", false).click((event) =>
        state = @$(event.target).prop("checked")
        @$("body")[if state then "addClass" else "removeClass"]("show-testers")
      )
      return Preferences.get({
        zoom_ratio_x10: 10
        device_filter: true
        beta_firmware: false
        log_verbosity: 0
        reset_all: false
        catalog_editor: false
      })
    ).then((items) =>
      App.info.verbose({"PrefController#activate": items})
      @$("#config-zoom-ratio").val("#{items.zoom_ratio_x10}").change((event) =>
        value = parseInt(@$(event.target).val())
        Preferences.set({zoom_ratio_x10: value})
        curRatio = (parseFloat(window.document.body.style.zoom) or 1)
        newRatio = value / 10
        bounds = @appWindow?.innerBounds
        newMinWidth = Math.round(bounds.minWidth / curRatio * newRatio)
        newMinHeight = Math.round(bounds.minHeight / curRatio * newRatio)
        bounds?.setMinimumSize(1, 1)
        bounds?.setSize(
          Math.round(bounds.width / curRatio * newRatio)
          Math.round(bounds.height / curRatio * newRatio)
        )
        bounds?.setMinimumSize(newMinWidth, newMinHeight)
        window.document.body.style.zoom = newRatio
      )
      @$("#config-device-filter").prop("checked", !!items.device_filter).click((event) =>
        value = !!@$(event.target).prop("checked")
        Preferences.set({device_filter: value})
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
      @$("#config-cateditor").prop("checked", !!items.catalog_editor).click((event) =>
        value = !!@$(event.target).prop("checked")
        Preferences.set({catalog_editor: value})
      )
    ).then(=>
      @$("body").addClass("controller-pref")
      return
    ) # return super().then()...

  ###*
  @protected
  @inheritdoc Controller#deactivate
  ###
  deactivate: ->
    @$("body").removeClass("controller-pref show-testers")
    @$("#config-for-testers").unbind("click")
    @$("#config-zoom-ratio").unbind("change")
    @$("#config-beta-firmware").unbind("change")
    @$("#config-log-verbosity").unbind("change")
    @$("#config-reset-all").unbind("change")
    return super()

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

# Post dependencies
I18n = require("util/i18n")
App = require("app/app")
Preferences = require("app/preferences")
