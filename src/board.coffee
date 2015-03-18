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
  @property
  Connection state
  ###
  isConnected: false

  ###*
  Callback called when user selects board
  ###
  onSelected: ->
    b = $("#group-board")
    p = $("#group-port")
    b.find(".ph-body").text(@constructor.boardname)
    p.find(".list-item").remove()
    p.find(".list-refresh").unbind("click").click(=>
      @onSelected()
    )
    p.find(".btn").prop("disabled", true).find(".ph-body").empty()
    p.find(".btn").prop("disabled", false)
    index = 0
    portClass.enumerate((ports) =>
      return if ports.length == 0
      for port in ports
        do (port) =>
          p.find(".list-alt").before("""
            <li class="list-item btn-xs">
              <a href="#" title="#{port.path}" id="port-item-#{index}">#{port.name}</a>
            </li>
            """
          )
          p.find("#port-item-#{index}").unbind("click").click(=>
            console.log("connecting to #{@constructor.boardname} via #{port.name}...")
            p.find(".ph-body").text(port.name)
            ModalSpin.show()
            @connect(port, (result) =>
              ModalSpin.hide()
              console.log({connect_status: result})
            )
          )
          index += 1
    ) for portClass in @constructor.portClasses

  ###*
  Callback called when connection state is changed
  @param {Boolean} state      New state
  ###
  onConnected: (state) ->
    @isConnected = state
    $("#group-board-info").find(".btn").prop("disabled", !state)
    $("#group-run").find(".btn").prop("disabled", !state)

  ###*
  Disconnect from board
  @param {Function} callback  Callback ({Boolean} result)
  ###
  disconnect: (callback) ->
    return callback(true) unless @isConnected
    @onConnected(false)
    callback(true)

  ###*
  @private
  Constructor
  ###
  constructor: @pureClass

  #----------------------------------------------------------------
  # UI initializations

  $(=>
    for boardClass in @_boards
      do (boardClass) ->
        b = $("#group-board")
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
          board = new boardClass()
          App.sketch.changeBoard(
            board,
            ((result) ->
              board.onSelected() if result
            )
          )
        )
        b.find(".btn").prop("disabled", false)
  )

  # $("#group-board-info").find(".btn").click(->
  #   console.log("sandbox")
  #   return App.sketch.board.dumpMemory(parseInt($("#hoge1").val()), parseInt($("#hoge2").val()))
  #   App.sketch.board.verbose = 3
  #   App.sketch.board.sendHttpRequest("GET", "/hoge", null, (code, response) ->
  #     console.log("code: #{code}, response: #{response}")
  #   )
  #   return
  #   ModalSpin.show()
  #   App.sketch.board.getInfo((result, info) ->
  #     ModalSpin.hide()
  #     bootbox.alert({
  #       title: "Board information",
  #       message: info
  #     })
  #   )
  # )

