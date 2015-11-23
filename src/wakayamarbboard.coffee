###*
@class
Wakayama.rb board support
###
class WakayamaRbBoard extends Board
  Board.addBoard(this)

  #----------------------------------------------------------------
  # Class attributes/methods

  @boardname: "Wakayama.rb Board"
  @author: "Minao Yamamoto (@momoonga)"
  @website: "https://github.com/tarosay/Wakayama-mruby-board"
  @portClasses: [SerialPort]

  #----------------------------------------------------------------
  # Instance attributes/methods

  ###*
  Constructor
  ###
  constructor: (config) ->
    super

  ###*
  Connect to Wakayama.rb board
  @param {Object}   port      Port object
  @param {Function} callback  Callback ({Boolean} result)
  ###
  connect: (port, callback) ->
    return callback(true) if @state > @UNAVAILABLE
    path = "#{port.path}"
    super(
      (callback) =>
        @constructor.portClasses[0].connect(path, {
          bitrate: 115200
          dataBits: "eight"
          parityBit: "no"
          stopBits: "one"
          ctsFlowControl: false
        }, (connection) =>
          callback(connection)
        )
      callback
    )
    return

  ###*
  Disconnect from Wakayama.rb board
  @param {Function} callback  Callback ({Boolean} result)
  ###
  disconnect: (callback) ->
    return callback?(true) if @state == @UNCONNECTED
    @connection.disconnect(=>
      super(callback)
    )
    return

  ###*
  Get board information
  @param {Function} callback  Callback ({Boolean} result, {Object} info)
  ###
  getInfo: (callback) ->
    @activate((result) =>
      unless result
        callback?(true, {message: "No information for this board"})
        return
      console.log(@connection)
      @connection.read("\r\n>".toUint8Array(), (result) =>
        lines = result.toUtf8String().split("\r\n")
        lines.pop()
        ver = lines.pop() or ""
        match = ver.match(/^WAKAYAMA\.RB Board ([^,]+),([^(]+)/)
        return callback?(false) unless match
        callback?(true, {boardVersion: match[1].trim(), mrubyVersion: match[2].trim()})
      )
      @connection.write("H\r".toArrayBuffer(), (result) =>
        callback?(false) unless result
      )
    )

