"use strict"
require("../util/primitive")
WindowController = require("./window-controller")

###*
Controller for preference view (Controller, Singleton, Renderer-process)

@class PrefController
@extends WindowController
###
module.exports =
class PrefController extends WindowController

  constructor: ->

  ###*
  The singleton instance of this class

  @property {MainController} instance
    The instance of this class
  @readOnly
  ###
  @staticProperty("instance", get: ->
    return @_instance or= new PrefController()
  )

  @_instance: null

  ###*
  Activate this controller

  @method activate
  @return {Promise|undefined}
    Promise object
  ###
  activate: ->
    return super(
    ).then(=>
      $("#config-for-testers").prop("checked", false).click((event) =>
        state = $(event.target).prop("checked")
        $("body").toggleClass("show-testers", state)
      )
      return global.bridge.settings.get({
        "window.zoom_ratio_x10": 10
        # device_filter: true
        confirm_net: true
        beta_firmware: false
        log_verbosity: 0
        reset_all: false
        # catalog_editor: false
      })
    ).then((items) =>
      $("#config-zoom-ratio").val("#{items["window.zoom_ratio_x10"]}").change((event) =>
        #value = parseInt($(event.currentTarget).val())
        #curRatio = (parseFloat(window.document.body.style.zoom) or 1)
        #newRatio = value / 10
        #bounds = @appWindow?.innerBounds
        #newMinWidth = Math.round(bounds.minWidth / curRatio * newRatio)
        #newMinHeight = Math.round(bounds.minHeight / curRatio * newRatio)
        #bounds?.setMinimumSize(1, 1)
        #bounds?.setSize(
        #  Math.round(bounds.width / curRatio * newRatio)
        #  Math.round(bounds.height / curRatio * newRatio)
        #)
        #bounds?.setMinimumSize(newMinWidth, newMinHeight)
        #window.document.body.style.zoom = newRatio
        #global.bridge.settings.set({"window.zoom_ratio_x10": value})
      )
      # $("#config-device-filter").prop("checked", !!items.device_filter).click((event) =>
      #   value = !!$(event.target).prop("checked")
      #   Preferences.set({device_filter: value})
      # )
      $("#config-noconfirm-net").prop("checked", !items.confirm_net).click((event) =>
        value = !($(event.currentTarget).prop("checked"))
        global.bridge.settings.set({confirm_net: value})
      )
      $("#config-beta-firmware").val("#{items.beta_firmware}").change((event) =>
        value = ($(event.currentTarget).val() != "false")
        global.bridge.settings.set({beta_firmware: value})
      )
      $("#config-log-verbosity").val("#{items.log_verbosity}").change((event) =>
        value = parseInt($(event.currentTarget).val())
        global.bridge.settings.set({log_verbosity: value})
      )
      $("#config-reset-all").val("#{items.reset_all}").change((event) =>
        value = ($(event.currentTarget).val() != "false")
        global.bridge.settings.set({reset_all: value})
        console.warn("All preferences will be cleared at the next boot!") if value
      )
      # $("#config-cateditor").prop("checked", !!items.catalog_editor).click((event) =>
      #   value = !!$(event.target).prop("checked")
      #   Preferences.set({catalog_editor: value})
      # )
    ).then(=>
      $("body").addClass("controller-pref")
      return
    ) # return super().then()...

  deactivate: ->
    $("body").removeClass("controller-pref show-testers")
    $("#config-for-testers").unbind("click")
    $("#config-zoom-ratio").unbind("change")
    $("#config-noconfirm-net").unbind("click")
    $("#config-beta-firmware").unbind("change")
    $("#config-log-verbosity").unbind("change")
    $("#config-reset-all").unbind("change")
    return super()

