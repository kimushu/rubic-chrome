"use strict"
# Pre dependencies
WindowController = require("controller/windowcontroller")

###*
@class BoardController
  Controller for board-catalog view (Controller, Singleton)
@extends WindowController
###
module.exports = class BoardController extends WindowController
  null
  instance = null

  #--------------------------------------------------------------------------------
  # Public properties
  #

  ###*
  @static
  @property {BoardController}
    The instance of this class
  @readonly
  ###
  @classProperty("instance", get: ->
    return instance or= new BoardController(window)
  )

  #--------------------------------------------------------------------------------
  # Private variables / constants
  #

  UPDATE_TIMEOUT = 5000
  AUTO_PAGE_TRANSITION = 500
  PAGES = ["catalog", "features", "iodef", "savecfg", "noboard"]
  setupDone = false
  tabSet = null

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
    @_board = null
    return

  #--------------------------------------------------------------------------------
  # Protected methods
  #

  ###*
  @inheritdoc Controller#activate
  ###
  activate: (initialPage) ->
    $ = @$
    initialPage or= (@_lastTabPage or "catalog")
    return super(
    ).then(=>
      # Setup jquery-scrollTabs (only once)
      return if tabSet?
      tabSet = $("#board-tabs").scrollTabs({
        left_arrow_size: 18
        right_arrow_size: 18
      })
    ).then(=>
      # Setup other HTML elements (only once)
      return if setupDone
      setupDone = true
      $(".main-outer.when-board > .editor-body").hide()
      $(".board-page-select").click(@_pageSelect.bind(this))
      $(".board-page-select[data-page=iodef]").hide()   # TODO: for future use
      $(".board-page-select[data-page=savecfg]").hide() # TODO: for future use
      $(".board-catalog-refresh").click(@_refreshCatalog.bind(this, true))
    ).then(=>
      # Initialize variables
      @_board = App.sketch?.board
    ).then(=>
      # Select initial tab
      @_lastTabPage = null  # Do not use animation
      $(".board-page-select[data-page=#{initialPage}]").click()
    ).then(=>
      # Refresh catalog (updated only if cache is old)
      @_refreshCatalog(false)
    ).then(=>
      # Show this controller
      $("body").addClass("controller-board")
    ) # return super().then()...

  ###*
  @inheritdoc Controller#deactivate
  ###
  deactivate: ->
    return Promise.resolve(
    ).then(=>
      return false if @_board?
      App.popupWarning(
        I18n.getMessage("Board_is_not_selected")
      )
      return true # Do not wait until notification closing
    ).then((skip) =>
      return true if skip
      return @_board.loadFirmware().catch(=> return)
    ).then((firmware) =>
      return true if firmware == true
      return false if firmware?
      App.popupWarning(
        I18n.getMessage("Firmware_is_not_selected")
      )
      return true # Do not wait until notification closing
    ).then((skip) =>
      return true if skip
      return @_board.loadFirmRevision().catch(=> return)
    ).then((firmRevision) =>
      return true if firmRevision == true
      return firmRevision if firmRevision?
      App.popupWarning(
        I18n.getMessage("Firmware_revision_is_not_selected")
      )
      return true # Do not wait until notification closing
    ).then((firmRevision) =>
      return true if firmRevision == true
      return firmRevision.checkCacheAvailability(
      ).then((available) =>
        return true if available
        msg = I18n.getMessage("Downloading_firmware")
        spin = @modalSpin().show()
        return firmRevision.download(
          false
          (url) =>
            return spin.html("#{msg}\n#{url}") if url?
            return spin.html(I18n.getMessage("Saving_firmware"))
        ).catch((error) =>
          App.popupError(
            I18n.getMessage("Firmware_download_failed")
          )
          return  # Do not wait until notification closing
        ).finally(=>
          spin.hide()
        ) # return firmRevision.download().then()...
      ) # return firmRevision.checkCacheAvailability().then()
    ).then(=>
      App.sketch?.board = @_board
      @$("body").removeClass("controller-board")
      return super()
    ) # return Promise.resolve().then()...

  #--------------------------------------------------------------------------------
  # Private methods
  #

  ###*
  @private
  @method
    Page select handler
  @param {Event} event
    DOM Event
  @return {Promise}
    Promise object
  ###
  _pageSelect: (event) ->
    $ = @$
    return Promise.resolve(
    ).then(=>
      page = event.target.dataset.page
      return unless page
      page = "noboard" unless page == "catalog" or @_board?
      return if @_lastTabPage == page # No tab change
      pageElements = $(".main-outer.when-board > .editor-body")
      pageElements.removeClass("slidein-rtl slidein-ltr")
      newElement = $("#board-page-#{page}")

      if @_lastTabPage
        # with animation
        oldElement = $("#board-page-#{@_lastTabPage}")
        oldElement.css("zIndex", 0)
        newElement.css("zIndex", 1)
        oldPos = PAGES.indexOf(@_lastTabPage)
        newPos = PAGES.indexOf(page)
        if newPos < oldPos
          # To left page (ltr)
          newElement.addClass("slidein-ltr")
        else
          # To right page (rtl)
          newElement.addClass("slidein-rtl")
        newElement.one("animationend", => oldElement.hide())
      else
        newElement.siblings(".editor-body").hide()

      # Show new page
      newElement.show()
      @_lastTabPage = page
      return
    ) # return Promise.resolve().then()

  ###*
  @private
  @method
    Refresh catalog page
  @param {boolean} force
    Force update
  @return {Promise}
    Promise object
  ###
  _refreshCatalog: (force = false) ->
    $ = @$
    tmpl = null
    return Promise.resolve(
    ).then(=>
      # Load from cache
      return BoardCatalog.load(false)
    ).then((@_boardCatalog) =>
      # Clear DOM elements
      (tmpl = $("#board-catalog-tmpl")).hide().siblings().remove()
      # Update
      return @_boardCatalog.update(force).timeout(
        UPDATE_TIMEOUT
      # ).catch(=>
      #   # TODO: warning
      )
    ).tap(
      # Print BoardCatalog instance (for debugging, verbose mode only)
      App.log.verbose
    ).then(=>
      for board in @_boardCatalog.boardClasses
        id = "board-#{board.name}"
        li = $("##{id}")
        (li = tmpl.clone()).appendTo(tmpl.parent()) unless li[0]
        li[0].id = id
        li[0].dataset.name = board.name
        li.find(".media-object")[0].src = board.images[0]
        li.find(".media-heading .placeholder").text(board.friendlyName)
        ph = li.find(".media-body > p .placeholder")
        ph.eq(0).text(@_boardCatalog.getDescription(board))
        ph.eq(1).text(board.author)
        ph.eq(2).attr("href", board.website)
        li.show()
        li.addClass("board-selected") if @_board?.constructor.name == board.name
      $(".board-use-this").unbind("click").click(@_boardSelect.bind(this))
      @_refreshFeatures()
    ) # return Promise.resolve().then()...

  ###*
  @private
  @method
    Board select handler
  @param {Event} event
    DOM event
  @return {Promise}
    Promise object
  ###
  _boardSelect: (event) ->
    $ = @$
    li = null
    boardClass = null
    return Promise.resolve(
    ).then(=>
      li = $(event.target).parents(".media").eq(0)
      name = li.data("name")
      boardClass = Board.subclasses.find((item) => item.name == name)
      return Promise.reject("Board class not found") unless boardClass?
      return "ok" if !@_board? or @_board?.constructor == boardClass
      return global.bootbox.dialog_p({
        title: I18n.getMessage("Confirm_board_change_title")
        message: I18n.getMessage("Confirm_board_change_message")
        closeButton: false
        buttons: {
          ok: {
            label: I18n.getMessage("Yes")
            className: "btn-danger"
          }
          cancel: {
            label: I18n.getMessage("No")
            className: "btn-success"
          }
        }
      })  # return global.bootbox.dialog_p()
    ).then((result) =>
      return unless result == "ok"
      li.siblings().removeClass("board-selected")
      li.addClass("board-selected")
      if !@_board? or @_board?.constructor != boardClass
        @_board = new boardClass()
      return @_refreshFeatures().then(=>
        return Promise.delay(AUTO_PAGE_TRANSITION).then(=>
          $(".board-page-select[data-page=features]").click()
        ) if AUTO_PAGE_TRANSITION?
      )
    ) # return Promise.resolve().then()...

  ###*
  @private
  @method
    Refresh DOM elements for features
  @param {null/"hwrev"/"fw"/"fwrev"} from
    Name of list to be updated
  @return {Promise}
    Promise object
  ###
  _refreshFeatures: (from) ->
    @$("#feature-board").text(@_board?.constructor.friendlyName or "")
    promises = []
    from = {hwrev: 0, fw: 1, fwrev: 2}[from] or 0
    promises.push(@_refreshBoardRevs()) if from <= 0
    promises.push(@_refreshFirms())     if from <= 1
    promises.push(@_refreshFwRevs())    if from <= 2
    return Promise.all(promises)

  ###*
  @private
  @method
    Refresh dropdown list
  @param {string} prefix
    DOM ID prefix
  @param {Object[]} list
    Array of items
  @param {function(string)} callback
    Callback when item clicked
  @param {Promise}
    Promise object (fulfilled when refresh completes)
  ###
  _refreshList: (prefix, list, callback) ->
    $ = @$
    (tmpl = $("##{prefix}-tmpl")).hide().siblings().remove()
    na = list?.length == 0
    (sel = $("##{prefix}-sel")).find(".placeholder").text(
      if na then "N/A" else "(#{I18n.getMessage("Select_one")})"
    )
    sel.prop("disabled", na)
    grp = tmpl.parents("div.form-group").eq(0)
    if list?
      grp.show()
    else
      grp.hide()
    return unless list?.length > 0
    for item in list
      do (item) =>
        (li = tmpl.clone()).appendTo(tmpl.parent())
        li[0].id = "#{prefix}-item-#{item.id}"
        li.find(".placeholder").text(item.text)
        li.find(".label-danger").hide() unless item.obsolete
        li.find(".label-warning").hide() unless item.beta
        (a = li.children("a")).click(=>
          sel.find(".placeholder").html(a.html())
          callback(item.id)
        )
        li.show()
        a.click() if item.selected
    return Promise.resolve()

  ###*
  @private
  @method
    Refresh board revision list
  @return {Promise}
    Promise object
  ###
  _refreshBoardRevs: ->
    revs = @_board?.boardRevisions or []
    list = ({text: val, id: idx} for val, idx in revs)
    selIdx = revs.indexOf(@_board?.boardRevision)
    list[selIdx].selected = true if selIdx >= 0
    list = null if list?.length <= 1
    return @_refreshList("brdrev", list, (idx) =>
      @_board.boardRevision = revs[parseInt(idx)]
      @_refreshFeatures("fw")
    )

  ###*
  @private
  @method
    Refresh firmware list
  @return {Promise}
    Promise object
  ###
  _refreshFirms: ->
    boardClass = @_board?.constructor
    return unless boardClass?
    @_firmCatalog = @_boardCatalog?.getFirmCatalog(boardClass)
    list = []
    for id in (@_firmCatalog?.getFirmwareIDs() or [])
      do (id) =>
        f = @_firmCatalog.getFirmware(id)
        list.push({
          id: id
          text: f.friendlyName.toString()
          obsolete: !!f.obsolete
          beta: !!f.beta
          selected: (@_board.firmwareId == id)
        }) if f?
    return @_refreshList("fw", list, (id) =>
      if @_board.firmwareId != id
        @_board.setFirmware(@_firmCatalog.getFirmware(id))
      return @_refreshFeatures("fwrev")
    )

  ###*
  @private
  @method
    Refresh firmware revision list
  @return {Promise}
    Promise object
  ###
  _refreshFwRevs: ->
    list = []
    firmwareId = @_board?.firmwareId
    if firmwareId?
      for id in (@_firmCatalog?.getFirmRevisionIDs(firmwareId) or [])
        do (id) =>
          r = @_firmCatalog.getFirmRevision(id)
          list.push({
            id: id
            text: r.friendlyName.toString()
            obsolete: !!r.obsolete
            beta: !!r.beta
            selected: (@_board.firmRevisionId == id)
          }) if r?
    dlReq = @$("#fwrev-dl-required").hide()
    return @_refreshList("fwrev", list, (id) =>
      if @_board.firmRevisionId != id
        @_board.setFirmRevision(@_firmCatalog.getFirmRevision(id))

      return @_board.loadFirmRevision(
      ).then((firmRevision) =>
        return firmRevision.checkCacheAvailability()
      ).then((available) =>
        if available
          dlReq.hide()
        else
          dlReq.show()
      )
    )

# Post dependencies
I18n = require("util/i18n")
App = require("app/app")
Board = require("board/board")
BoardCatalog = require("firmware/boardcatalog")
