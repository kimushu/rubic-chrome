###*
@class Rubic.CatalogController
  Controller for catalog window (Singleton, Controller)
@extends Rubic.WindowController
###
class Rubic.CatalogController extends Rubic.WindowController
  DEBUG = Rubic.DEBUG or 0

  ###*
  @method
    Start controller
  @return {void}
  ###
  start: ->
    super(
      "win_catalog.html"
      {
        innerBounds: {
          width: 640
          height: 480
          minWidth: 480
        }
      }
    )
    return

