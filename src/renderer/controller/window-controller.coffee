"use strict"
require("../../util/primitive")
Controller = require("./controller")
once = require("once")

###*
Base controller for main window (Controller, Renderer-process)

@class WindowController
@extends Controller
###
module.exports =
class WindowController extends Controller

  constructor: ->
    super

  activate: ->
    return super(
    ).then(=>
      return @_setupWindow()
    ).then(=>
      @setTitle()
    ) # return super().then()

  deactivate: ->
    return super()

  ###*
  Set window title with Rubic prefix

  @method setTitle
  @param {string} [str]
    Suffix string
  @return {undefined}
  ###
  setTitle: (str) ->
    if str? and str != ""
      str = " - #{str.toString()}"
    else
      str = ""
    window.document.title = global.rubic.name + str
    return

  ###*
  Setup HTML contents for the first time

  @private
  @method _setupWindow
  @return {Promise|undefined}
  ###
  _setupWindow: once ->
    # navbar-top left
    $(".show-left").click(=> $("body").removeClass("left-hidden"))
    $(".hide-left").click(=> $("body").addClass("left-hidden"))

    # Menu items
    activator = (_class) => => _class.instance.activate()
    $(".activate-main").click(activator(MainController))
    $(".activate-pref").click(activator(PrefController))
    $(".activate-tutorial").click(activator(TutorialController))
    $(".activate-about").click(activator(AboutController))
    $(".activate-board").click(activator(BoardController))

    # Folding
    $(".fold-toggle").click((event) =>
      $(event.target).parents(".fold-header").eq(0)
        .toggleClass("fold-opened")
    )

    # Install keybind listener
    $(window.document).keydown(@_processKey.bind(this))

    return Promise.resolve()

  ###*
  Flags for subclasses

  @protected
  @property {Object} flags
  @readOnly
  ###
  @getter "flags", -> (window._controllerFlags ?= {})[@constructor.name] ?= {}

  ###*
  Launch controller

  @static
  @method launch
  @return {undefined}
  ###
  @launch: ->
    MainController.instance.activate()
    return

MainController = require("./main-controller")
PrefController = require("./pref-controller")
TutorialController = null #require("./tutorial-controller")
AboutController = require("./about-controller")
BoardController = null #require("./board-controller")
