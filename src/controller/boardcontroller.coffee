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
  PAGES = ["catalog", "features", "iodef", "savecfg"]
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
  @inheritdoc Controller#onActivated
  ###
  onActivated: (tab) ->
    super
    @_board = App.sketch?.board
    tab or= "catalog" unless tabSet?
    tabSet or= @$("#board-tabs").scrollTabs({
      left_arrow_size: 18
      right_arrow_size: 18
      click_callback: @_tabClick.bind(@)
    })
    for page in PAGES
      do (id = "board-#{page}") =>
        @$("#page-board-#{page}")[0].dataset.page = page
        @$(".activate-#{id}").unbind("click").click(=>
          @$("#page-#{id}").click()
        )
    @$("#page-board-iodef").hide()    # TODO
    @$("#page-board-savecfg").hide()  # TODO
    @_lastTabPage = null
    @$("#page-board-#{tab}").click() if tab?
    @_refreshCatalog()
    @$(".catalog-refresh").unbind("click").click(=>
      @_refreshCatalog(true).then(=>
        @_refreshFeatures()
      )
    )
    @$("body").addClass("controller-board")
    return

  ###*
  @inheritdoc Controller#onDeactivated
  ###
  onDeactivated: ->
    App.sketch?.board = @_board
    @$("body").removeClass("controller-board")
    outer = @$(".main-outer.when-board")
    header = outer.children(".config-header")
    header.find("a").unbind("click")
    @$(".board-use-this").unbind("click")
    super
    return

  #--------------------------------------------------------------------------------
  # Private methods
  #

  ###*
  @private
  @method
    Tab click callback
  @param {DOMElement} element
    Element
  @param {Event} event
    Event
  @return {undefined}
  ###
  _tabClick: (event) ->
    page = event.target.dataset.page
    return unless page
    newTabPage = page
    oldTabPage = @_lastTabPage
    return if newTabPage == oldTabPage
    el = @$(".when-board > .editor-body").removeClass("slidein-rtl slidein-ltr")
    el.not("#board-#{oldTabPage}").hide()
    el.not("#board-#{newTabPage}").css("zIndex", 0)
    el.filter("#board-#{newTabPage}").css("zIndex", 1)
    page = "noboard" unless page == "catalog" or @_board?
    el = @$("#board-#{page}")
    if oldTabPage?
      oldTabPos = PAGES.indexOf(oldTabPage)
      newTabPos = PAGES.indexOf(newTabPage)
      if newTabPos < oldTabPos
        # Left -> Right animation
        el.addClass("slidein-ltr")
      else
        # Left <- Right animation
        el.addClass("slidein-rtl")
    @_lastTabPage = newTabPage
    el.show()
    el.on("animationend", =>
      @$("#board-#{oldTabPage}").hide()
    )
    return

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
    (tmpl = @$("#board-catalog-tmpl")).hide().siblings().remove()
    @_boardCatalog = null
    return Promise.resolve(
    ).then(=>
      return BoardCatalog.load(false)
    ).then((catalog) =>
      @_boardCatalog = catalog
      return @_boardCatalog.update(force).timeout(
        UPDATE_TIMEOUT
      # ).catch(=>
      #   # TODO: warning
      )
    ).then(=>
      App.log(@_boardCatalog)
      for board in @_boardCatalog.boardClasses
        id = "board-#{board.name}"
        li = @$("##{id}")
        (li = tmpl.clone()).appendTo(tmpl.parent()) unless li[0]
        li[0].id = id
        li[0].dataset.name = board.name
        li.find(".media-object")[0].src = board.images[0]
        li.find(".media-heading .placeholder").text(board.friendlyName)
        ph = li.find(".media-body > p .placeholder")
        @$(ph[0]).text(@_boardCatalog.getDescription(board))
        @$(ph[1]).text(board.author)
        @$(ph[2]).attr("href", board.website)
        li.show()
        li.addClass("board-selected") if @_board?.constructor.name == board.name
      @$(".board-use-this").unbind("click").click((event) =>
        li = @$(event.target).parents(".media")
        name = li.data("name")
        li.siblings().removeClass("board-selected")
        li.addClass("board-selected")
        for board in Board.subclasses
          continue unless board.name == name
          if @_board?.constructor != board
            # overwrite confirmation
            @_board = new board()
          @$("#feature-board").text(@_board.constructor.friendlyName)
          @_refreshFeatures()
          Promise.delay(AUTO_PAGE_TRANSITION).then(=>
            @$("li#page-board-features").click()
          ) if AUTO_PAGE_TRANSITION?
          break
      ) # @$(".board-use-this").unbind()...
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
  ###
  _refreshList: (prefix, list, callback) ->
    (tmpl = @$("##{prefix}-tmpl")).hide().siblings().remove()
    na = list?.length == 0
    (sel = @$("##{prefix}-sel")).find(".placeholder").text(
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
        li.find(".dl-required").hide() unless item.download
        (a = li.children("a")).click(=>
          sel.find(".placeholder").html(a.html())
          callback(item.id)
        )
        li.show()
        a.click() if item.selected
    return

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
    selIdx = revs.indexOf(@_board.boardRevision)
    list[selIdx].selected = true if selIdx >= 0
    list = null if list?.length <= 1
    @_refreshList("brdrev", list, (idx) =>
      @_board.boardRevision = revs[parseInt(idx)]
      @_refreshFeatures("fw")
    )
    return Promise.resolve()

  ###*
  @private
  @method
    Refresh firmware list
  @return {Promise}
    Promise object
  ###
  _refreshFirms: ->
    @_firmCatalog = @_boardCatalog?.getFirmCatalog(@_board?.constructor)
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
    @_refreshList("fw", list, (id) =>
      if @_board.firmwareId != id
        @_board.setFirmware(@_firmCatalog.getFirmware(id))
      return @_refreshFeatures("fwrev")
    )
    return Promise.resolve()

  ###*
  @private
  @method
    Refresh firmware revision list
  @return {Promise}
    Promise object
  ###
  _refreshFwRevs: ->
    list = []
    for id in (@_firmCatalog?.getFirmRevisionIDs(@_board.firmwareId) or [])
      do (id) =>
        r = @_firmCatalog.getFirmRevision(id)
        list.push({
          id: id
          text: r.friendlyName.toString()
          obsolete: !!r.obsolete
          beta: !!r.beta
          selected: (@_board.firmRevisionId == id)
        }) if r?
    @_refreshList("fwrev", list, (id) =>
      if @_board.firmRevisionId != id
        @_board.setFirmRevision(@_firmCatalog.getFirmRevision(id))
      return
    )
    return Promise.resolve()

# Post dependencies
I18n = require("util/i18n")
App = require("app/app")
Board = require("board/board")
BoardCatalog = require("firmware/boardcatalog")
