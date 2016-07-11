# Pre dependencies
WindowController = require("./windowcontroller")

###*
@class TutorialController
  Controller for tutorial view (Controller, Singleton)
@extends Controller
###
class TutorialController extends WindowController
  null
  instance = null

  #--------------------------------------------------------------------------------
  # Public properties
  #

  ###*
  @static
  @property {TutorialController}
    The instance of this class
  @readonly
  ###
  @classProperty("instance", get: ->
    return instance or= new TutorialController(window)
  )

  #--------------------------------------------------------------------------------
  # Public methods
  #

  ###*
  @method constructor
    Constructor of MainController class
  @param {Window} window
    window object
  ###
  constructor: (window) ->
    super(window)
    return

  #--------------------------------------------------------------------------------
  # Protected methods
  #

  ###*
  @inheritdoc Controller#onActivated
  ###
  onActivated: ->
    super
    @$("body").addClass("controller-tutorial")
    return

  ###*
  @inheritdoc Controller#onDeactivated
  ###
  onDeactivated: ->
    @$("body").removeClass("controller-tutorial")
    super
    return

module.exports = TutorialController

# Post dependencies
I18n = require("./i18n")
Preferences = require("./preferences")
