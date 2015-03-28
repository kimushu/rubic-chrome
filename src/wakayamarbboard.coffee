###*
@class
Wakayama.rb board support
###
class WakayamaRbBoard extends Board
  Board.addBoard(this)

  #----------------------------------------------------------------
  # Class attributes/methods

  @boardname: "Wakayama.rb"
  @author: "Minao Yamamoto (@momoonga)"
  @website: ""
  @portClasses: [SerialPort]

  #----------------------------------------------------------------
  # Instance attributes/methods

  ###*
  Constructor
  ###
  constructor: (config) ->
    null

  ###*
  Connect to Wakayama.rb board
  @param {Object}   port      Port object
  @param {Function} callback  Callback ({Boolean} result)
  ###
  connect: (port, callback) ->
    return callback(true) if @isConnected
    @constructor.portClasses[0].connect(path, {
      bitrate: 115200
      dataBits: "eight"
      parityBit: "no"
      stopBits: "one"
      ctsFlowControl: false
    }, (result, connection) =>
      return callback(false) unless result
      @connection = connection
    ) # @constructor.portClasses[0].connect

