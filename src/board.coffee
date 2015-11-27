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

  UNCONNECTED:  0
  UNAVAILABLE:  1
  WAITING:      2
  RUNNING:      3

  #----------------------------------------------------------------
  # Instance attributes/methods

  ###*
  ###
  activate: (callback) ->
    if @connection
      callback(true)
      return
    @connector((@connection) =>
      @temporary = {}
      return callback(false) unless @connection
      @connection.onDisconnected = =>
        @connection = null
        @state = @UNAVAILABLE
        @temporary = {}
      @state = @WAITING
      callback(true)
    )
    return

  ###*
  Get board information
  @param {Function} callback  Callback ({Boolean} result, {Object} info)
  ###
  getInfo: (callback) ->
    @activate(=>
      callback?(true, {message: "No information for this board"})
    )
    return

  ###*
  Connect to board
  ###
  connect: (@connector, callback) ->
    @connection = null
    @activate(callback)
    return

  ###*
  Disconnect from board
  @param {Function} callback  Callback ({Boolean} result)
  ###
  disconnect: (callback) ->
    if @state <= @UNAVAILABLE
      @state = @UNCONNECTED
      callback(true)
      return
    @connection.disconnect((result) =>
      @state = if result then @UNCONNECTED else @UNAVAILABLE
      Notify.info("Disconnected") if result
      @connection = null
      callback(result)
    )
    return

  @property("state",
    get: -> @_state
    set: (v) ->
      return if @_state == v
      @_state = v
      @onStateChange?(v)
  )

  ###*
  @private
  Constructor
  ###
  constructor: ->
    @_state = @UNCONNECTED
    @onStateChange = null
    return

  ###*
  [UI action] Refresh port list
  ###
  uiRefreshPorts: ->
    b = $("#group-board")
    p = $("#group-port")
    p.find(".list-item").remove()
    p.find(".list-refresh").unbind("click").click(=> @uiRefreshPorts())
    p.find(".btn").prop("disabled", false).find(".ph-body").empty()
    @disconnect(=> return)
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
            ModalSpin.show()
            @connect(port, (result) =>
              ModalSpin.hide()
              if result
                @port = port
                Notify.success("Connected #{@constructor.boardname} on #{port.name}")
              else
                @port = null
                p.find(".ph-body").text("")
                Notify.error("Cannot connect #{@constructor.boardname} on #{port.name}")
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

  @selectBoardFromClassName: (name) ->
    e = $("#board-item-#{name}")
    if e[0]
      e.click()
    else
      b = $("#group-board")
      b.find(".ph-body").empty()
      p = $("#group-port")
      p.find(".list-item").remove()
      p.find(".list-refresh").unbind("click").click(=> @uiRefreshPorts())
      p.find(".btn").prop("disabled", false).find(".ph-body").empty()
    return

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
            }" title="Author: #{boardClass.author\
            }&#10;Website: #{boardClass.website\
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
    ModalSpin.show()
    @getInfo((result, info) =>
      ModalSpin.hide()
      return Notify.error("Failed to get board information") unless result
      message = ("#{key}: #{val}" for key, val of info).join("<br/>")
      bootbox.alert({
        title: "Board information (#{@constructor.boardname} on #{@port.name})"
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
    ModalSpin.show()
    final = (result) ->
      ModalSpin.hide()
      callback?(result)
    @stop((result) =>
      unless result
        App.lastError = "Cannot stop running sketch"
        return final(false)
      @download(sketch, (result) =>
        unless result
          App.lastError = "Cannot download new sketch"
          return final(false)
        @run((result) =>
          unless result
            App.lastError = "Cannot start new sketch"
            return final(false)
          final(true)
        ) # @run
      ) # @download
    ) # @stop

  ###
  [UI action] "Run" button
  ###
  @runSketch: ->
    return unless board = App.sketch?.board
    return unless board.state > board.UNCONNECTED
    ModalSpin.show()
    Sketch.uiBuildSketch((result) ->
      sketch = App.sketch
      sketch.board.uiDownloadAndRun(sketch, (result) ->
        ModalSpin.hide()
        if result
          Notify.success("Download succeeded.")
        else
          Notify.error("Download failed. (#{App.lastError})")
      )
    ) # Sketch.uiBuildSketch

  ###
  [UI event] Clicking "Run" button
  ###
  $(".action-run-sketch").click(=>
    Editor.focus()
    @runSketch()
  )
  KeyBind.add("Ctrl+R", "Run", => @runSketch())

