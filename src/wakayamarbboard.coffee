class WakayamaRbBoard extends Board
  Board.addBoard(this)
  @boardname: "Wakayama.rb"
  @author: "Minao Yamamoto (@momoonga)"
  @website: ""
  @portClasses: [SerialPort]

  ###*
  Constructor
  ###
  constructor: (config) ->
    super()

  ###*
  Connect to Wakayama.rb board
  @param {Object}   port      Port object
  @param {Function} callback  Callback ({Boolean} result)
  ###
  connect: (port, callback) ->
    return callback(true) if @isConnected
    @onConnected(false)

