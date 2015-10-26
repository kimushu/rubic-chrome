###*
@class Rubic.WakayamaRbBoard
  Wakayama.rb board (Model)
@extends Rubic.Board
###
class Rubic.WakayamaRbBoard extends Rubic.Board
  DEBUG = Rubic.DEBUG or 0
  Rubic.Board.addBoard(this)

  ###*
  @static
  @cfg {string}
    Name of board
  @readonly
  ###
  @NAME: "Wakayama.rb board"

  ###*
  @static
  @cfg {string}
    Author of board
  @readonly
  ###
  @AUTHOR: "Minao Yamamoto (@momoonga)"

  ###*
  @static
  @cfg {string}
    Website of board (if available)
  @readonly
  ###
  @WEBSITE: "https://github.com/tarosay/Wakayama-mruby-board"

  ###*
  @static
  @inheritdoc Board#enumerate
  ###
  @enumerate: (callback) ->
    # TODO
    return

  #----------------------------------------------------------------
  # >>>> OLD contents >>>>

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

