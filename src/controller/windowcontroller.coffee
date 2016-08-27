"use strict"
# Pre dependencies
Controller = require("controller/controller")

###*
@class WindowController
  Base controller for window.html (Controller)
@extends Controller
###
module.exports = class WindowController extends Controller
  null

  #--------------------------------------------------------------------------------
  # Private variables / constants
  #

  setupDone = false

  #--------------------------------------------------------------------------------
  # Protected methods
  #

  ###*
  @protected
  @method constructor
    Constructor of WindowController class
  @param {Window} window
    window object
  ###
  constructor: (window) ->
    super(window)
    return

  ###*
  @inheritdoc Controller#activate
  ###
  activate: ->
    $ = @$
    return super(
    ).then(=>
      # Setup common HTML elements (only once)
      return if setupDone
      setupDone = true

      # navbar-top left
      $(".show-left").click(=> $("body").removeClass("left-hidden"))
      $(".hide-left").click(=> $("body").addClass("left-hidden"))

      # Menu items
      activate = (_class) =>
        $(".hide-left").click()
        _class.instance.activate()
      $(".activate-main").click(activate.bind(this, MainController))
      $(".activate-pref").click(activate.bind(this, PrefController))
      $(".activate-tutorial").click(activate.bind(this, TutorialController))
      $(".activate-about").click(activate.bind(this, AboutController))
      $(".activate-board").click(activate.bind(this, BoardController))

      # Folding
      $(".fold-toggle").click((event) =>
        $(event.target).parents(".fold-header").eq(0)
          .toggleClass("fold-opened")
      )
      return
    ) # return super().then()

  ###*
  @inheritdoc Controller#deactivate
  ###
  deactivate: ->
    return super()

# Post dependencies
MainController = require("controller/maincontroller")
PrefController = require("controller/prefcontroller")
TutorialController = require("controller/tutorialcontroller")
AboutController = require("controller/aboutcontroller")
BoardController = require("controller/boardcontroller")
