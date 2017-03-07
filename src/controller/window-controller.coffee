"use strict"
require("../util/primitive")
Controller = require("./controller")

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
      # Setup common HTML elements
      return if @flags.setupDone

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

      @flags.setupDone = true
      return
    ) # return super().then()

  deactivate: ->
    return super()

MainController = require("./main-controller")
PrefController = require("./pref-controller")
TutorialController = null #require("./tutorial-controller")
AboutController = null #require("./about-controller")
BoardController = null #require("./board-controller")
