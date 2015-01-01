class PeridotBoard extends Board
  Board.add(this)

  @boardname: "PERIDOT"
  @author: "@s_osafune"
  @website: "https://peridotcraft.com/"
  @comm: [SerialComm]

  constructor: (config) ->
    config ?= {}
    @_comm = Comm.load(config.comm)

  selected: ->
    super()

