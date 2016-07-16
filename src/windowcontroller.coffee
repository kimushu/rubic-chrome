# Pre dependencies
Controller = require("./controller")

###*
@class WindowController
  Base controller for window.html (Controller)
###
class WindowController extends Controller
  null

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
  @inheritdoc Controller#onActivated
  ###
  onActivated: ->
    super
    @$(".show-left").click(=> @$("body").removeClass("left-hidden"))
    @$(".hide-left").click(=> @$("body").addClass("left-hidden"))
    act = (c) => return =>
      @$(".hide-left").click()
      c.instance.activate()
    @$(".activate-main").click(act(MainController))
    @$(".activate-pref").click(act(PrefController))
    @$(".activate-tutorial").click(act(TutorialController))
    @$(".activate-about").click(act(AboutController))
    @$(".activate-board").click(act(BoardController))
    @$(".fold-toggle").click((event) =>
      @$(event.target).parents(".fold-header").toggleClass("fold-opened")
    )
    return

  ###*
  @inheritdoc Controller#onDeactivated
  ###
  onDeactivated: ->
    @$(".show-left").unbind("click")
    @$(".hide-left").unbind("click")
    @$(".activate-main").unbind("click")
    @$(".activate-pref").unbind("click")
    @$(".activate-tutorial").unbind("click")
    @$(".activate-about").unbind("click")
    @$(".fold-toggle").unbind("click")
    super
    return

module.exports = WindowController

# Post dependencies
MainController = require("./maincontroller")
PrefController = require("./prefcontroller")
TutorialController = require("./tutorialcontroller")
AboutController = require("./aboutcontroller")
BoardController = require("./boardcontroller")
