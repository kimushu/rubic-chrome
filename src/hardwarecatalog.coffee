###*
@class
Hardware catalog
###
class HardwareCatalog
  WINDOW_ID = "HardwareCatalog"

  #----------------------------------------------------------------
  # Class variables/methods

  ###*
  @static
  Show hardware catalog window
  ###
  @show: () ->
    (@_instance or= new HardwareCatalog).open()

  ###*
  @static
  Hide hardware catalog window
  ###
  @hide: () ->
    @_instance?.close()

  ###*
  @static
  @private
  Only instance of this class (singleton)
  ###
  @_instance: null

  #----------------------------------------------------------------
  # Instance variables/methods

  ###*
  Open new window / Bring existing window to top
  ###
  open: () ->
    return @_appWindow.focus() if @_appWindow
    chrome.app.window.create(
      "catalog.html",
      {id: WINDOW_ID},
      (createdWindow) =>
        console.log(createdWindow)
        @_appWindow = createdWindow
        @_appWindow.onClosed.addListener(=> @_appWindow = null)
    )

  ###*
  Close window
  ###
  close: () ->
    @_appWindow?.close()

  ###*
  @private
  Chrome AppWindow instance
  ###
  _appWindow: null

console.log({"HardwareCatalog": HardwareCatalog})

