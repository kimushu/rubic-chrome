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
    @$(".activate-main").click(=> MainController.instance.activate())
    @$(".activate-pref").click(=> PrefController.instance.activate())
    @$(".activate-tutorial").click(=> TutorialController.instance.activate())
    @$(".activate-about").click(=> AboutController.instance.activate())
    @$(".activate-board").click(=> BoardController.instance.activate())
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
# (none)
MainController = require("./maincontroller")
PrefController = require("./prefcontroller")
TutorialController = require("./tutorialcontroller")
AboutController = require("./aboutcontroller")
BoardController = require("./boardcontroller")
