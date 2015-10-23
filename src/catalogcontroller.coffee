###*
@class Rubic.CatalogController
  Controller for catalog window (Singleton, Controller)
@extends Rubic.WindowController
###
class Rubic.CatalogController extends Rubic.WindowController
  DEBUG = Rubic.DEBUG or 0

  ###*
  @method constructor
    Constructor of CatalogController
  ###
  constructor: ->
    super
    return

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
      =>
        @window.app.catalog = this
    )
    return

  ###*
  @protected
  @method
    Event handler on document.onload
  @return {void}
  ###
  onLoad: ->
    super()
    @$(".act-refresh").click(=> @_refreshCatalog())
    return

