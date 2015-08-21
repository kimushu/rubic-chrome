###*
@class
Hardware catalog
###
class HardwareCatalog
  WINDOW_ID = "HardwareCatalog"

  #----------------------------------------------------------------
  # Class variables/methods

  @show: () ->
    return @_appWindow.focus() if @_appWindow
    chrome.app.window.create(
      "catalog.html",
      {id: WINDOW_ID},
      (createdWindow) =>
        @_appWindow = createdWindow
        @_appWindow.onClosed.addListener(=> @_appWindow = null)
    )

  @hide: () ->
    null

  @_appWindow: null


