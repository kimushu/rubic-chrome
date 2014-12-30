class PeridotBoard extends Board
  @boardname: "PERIDOT"
  @author: "@s_osafune"
  @website: "https://peridotcraft.com/"
  @interface: [Serial]

  constructor: (config) ->
    config = config or {}
    @_port = config.port

  selected: ->
    super()

Board.list.push PeridotBoard
