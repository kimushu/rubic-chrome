###*
@class
Base class for embedded boards
###
class Board
  #----------------------------------------------------------------
  # Class attributes/methods

  ###*
  @protected
  Register board class
  ###
  @addBoard: (board) -> @_boards.push(board)

  ###*
  @private
  @property
  List of board classes
  ###
  @_boards: []

  #----------------------------------------------------------------
  # Instance attributes/methods

  ###*
  Get board information
  @param {Function} callback  Callback ({Boolean} result, {Object} info)
  ###
  getInfo: (callback) ->
    callback?(true, {message: I18n("NoInformationForThisBoard")})

  ###*
  Disconnect from board
  @param {Function} callback  Callback ({Boolean} result)
  ###
  disconnect: (callback) ->
    return callback?(true) unless @isConnected
    App.info(I18n("Disconnected"))
    @isConnected = false
    callback?(true)

  ###*
  @property
  @readonly
  Connection state
  ###
  isConnected: false

  ###*
  @private
  Constructor
  ###
  constructor: @pureClass

  ###*
  [UI action] Refresh port list
  ###
  uiRefreshPorts: ->
    b = $("#group-board")
    p = $("#group-port")
    p.find(".list-item").remove()
    p.find(".list-refresh").unbind("click").click(=> @uiRefreshPorts())
    p.find(".btn").prop("disabled", false).find(".ph-body").empty()
    index = 0
    portClass.enumerate((ports) =>
      return unless ports.length > 0
      for port in ports
        do (port) =>
          p.find(".list-alt").before("""
            <li class="list-item btn-xs">
              <a href="#" title="#{port.path}" id="port-item-#{index}">#{port.name}</a>
            </li>
            """
          )
          p.find("#port-item-#{index}").unbind("click").click(=>
            p.find(".ph-body").text(port.name)
            App.showModalSpin()
            @connect(port, (result) =>
              App.hideModalSpin()
              if result
                @port = port
                App.success(I18n("Board_Connected", @constructor.boardname, port.name))
              else
                @port = null
                App.error(I18n("Board_CannotConnect", @constructor.boardname, port.name))
              @constructor.uiChangeButtonState(result)
            )
          )
          p.find(".btn").prop("disabled", false) if index == 0
          index += 1
    ) for portClass in @constructor.portClasses

  ###*
  [UI action] Select new board
  ###
  @uiSelectNewBoard: (boardClass) ->
    b = $("#group-board")
    sketch = App.sketch
    unless sketch
      b.find(".ph-body").empty()
      return
    sketch.setBoard(boardClass, (result, board) =>
      return unless result
      @uiChangeButtonState(false)
      b.find(".ph-body").text(boardClass.boardname)
      board.uiRefreshPorts()
    )

  ###
  [UI initialization]
  ###
  $(=>
    b = $("#group-board")
    for boardClass in @_boards
      do (boardClass) =>
        b.find(".dropdown-menu").append("""
          <li class="btn-xs">
            <a href="#" id="board-item-#{boardClass.name\
            }" title="#{I18n("Author")}: #{boardClass.author\
            }&#10;#{I18n("Website")}: #{boardClass.website\
            }">#{boardClass.boardname}</a>
          </li>
          """
        )
        b.find("#board-item-#{boardClass.name}").unbind("click").click(=>
          Editor.focus()
          @uiSelectNewBoard(boardClass)
        )
        b.find(".btn").prop("disabled", false)
  )

  @selectBoard: (name) ->
    $("#board-item-#{name}").click()

  ###
  [UI action] Enable board access
  ###
  @uiChangeButtonState: (enabled) ->
    $(".action-board-info").prop("disabled", !enabled)
    $(".action-run-group").prop("disabled", !enabled)

  ###*
  [UI action] Show board information
  ###
  uiShowInfo: ->
    App.showModalSpin()
    @getInfo((result, info) =>
      App.hideModalSpin()
      return App.error(I18n("FailedToGetBoardInformation")) unless result
      message = ("#{key}: #{val}" for key, val of info).join("<br/>")
      bootbox.alert({
        title: "#{I18n("BoardInformation")} (#{@constructor.boardname} on #{@port.name})"
        message:message
      })
    )

  ###
  [UI event] Clicking "Board info" button
  ###
  $(".action-board-info").click(->
    Editor.focus()
    App.sketch?.board?.uiShowInfo()
  )

  ###*
  [UI action] Download & run
  ###
  uiDownloadAndRun: (sketch, callback) ->
    App.showModalSpin()
    final = (result) ->
      App.hideModalSpin()
      callback?(result)
    @stop((result) =>
      unless result
        App.lastError = I18n("CannotStopRunningSketch")
        return final(false)
      @download(sketch, (result) =>
        unless result
          App.lastError = I18n("CannotDownloadNewSketch")
          return final(false)
        @run((result) =>
          unless result
            App.lastError = I18n("CannotStartNewSketch")
            return final(false)
          final(true)
        ) # @run
      ) # @download
    ) # @stop

  ###
  [UI action] "Run" button
  ###
  @runSketch: ->
    return unless App.sketch?.board?.isConnected?
    App.showModalSpin()
    Sketch.uiBuildSketch((result) ->
      sketch = App.sketch
      sketch.board.uiDownloadAndRun(sketch, (result) ->
        App.hideModalSpin()
        if result
          App.success(I18n("DownloadSucceeded"))
        else
          App.error("#{I18n("DownloadFailed")} (#{App.lastError})")
      )
    ) # Sketch.uiBuildSketch

  ###
  [UI event] Clicking "Run" button
  ###
  $(".action-run-sketch").click(=>
    Editor.focus()
    @runSketch()
  )
  App.bindKey("Ctrl+R", "Run", => @runSketch())

