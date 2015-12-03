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

  WRBB_POLL_BYTE = 0xfe
  # WRBB_POLL_BYTE = undefined

  WRBB_MRB_DATA = new Uint8Array([
    # System.fileload()
    0x52,0x49,0x54,0x45,0x30,0x30,0x30,0x33,0x53,0x97,0x00,0x00,
    0x00,0x60,0x4d,0x41,0x54,0x5a,0x30,0x30,0x30,0x30,0x49,0x52,
    0x45,0x50,0x00,0x00,0x00,0x42,0x30,0x30,0x30,0x30,0x00,0x00,
    0x00,0x3a,0x00,0x01,0x00,0x03,0x00,0x00,0x00,0x00,0x00,0x03,
    0x00,0x80,0x00,0x11,0x00,0x80,0x40,0x20,0x00,0x00,0x00,0x4a,
    0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x02,0x00,0x06,0x53,0x79,
    0x73,0x74,0x65,0x6d,0x00,0x00,0x08,0x66,0x69,0x6c,0x65,0x6c,
    0x6f,0x61,0x64,0x00,0x45,0x4e,0x44,0x00,0x00,0x00,0x00,0x08,
  ]).buffer

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
          ctsFlowControl: true
        }, (connection) =>
          connection.setPollByte(WRBB_POLL_BYTE)
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
      @_command("H", (result) =>
        count = 0
        # push = =>
        #   console.log({time:parseInt(window.performance.now()), push:true, count: count++})
        #   @connection.write(" ".toArrayBuffer(), => return)
        # id = window.setInterval(push, 200)
        @connection.read("\r\n>".toUint8Array(), (result) =>
          # window.clearInterval(id)
          lines = result.toUtf8String().split("\r\n")
          lines.pop()
          @version_line = lines.pop() or ""
          match = @version_line.match(/^WAKAYAMA\.RB Board ([^,]+),([^(]+)/)
          return callback?(false) unless match
          console.log("================================================================================")
          callback?(true, {board_version: match[1].trim(), mruby_version: match[2].trim()})
        )
      )
    )

  _command: (cmd, callback) ->
    @connection.setPollByte(WRBB_POLL_BYTE)
    @connection.write("#{cmd}\r".toArrayBuffer(), (result) =>
      @connection.read("\r\n".toUint8Array(), (result) =>
        callback(true)
      )
    )
    return

  HEX2ASCII = [0x30..0x39].concat([0x41..0x46])

  _writeFile: (name, data, callback) ->
    @connection.setPollByte()
    @_command("U #{name} #{data.byteLength * 2}", (result) =>
      return callback?(false) unless result
      @connection.read("Waiting ".toUint8Array(), =>
        b2a = new Uint8Array(data.byteLength * 2)
        for byte, index in new Uint8Array(data)
          b2a[index * 2 + 0] = HEX2ASCII[(byte >>> 4) & 15]
          b2a[index * 2 + 1] = HEX2ASCII[(byte >>> 0) & 15]
        @connection.write(b2a.buffer, (result) =>
          return callback?(false) unless result
          @connection.read("Saving..".toUint8Array(), =>
            @connection.read("\r\n>".toUint8Array(), =>
              callback?(true)
            )
          )
        )
      )
    )
    return

  ###*
  Download sketch
  ###
  download: (sketch, callback) ->
    name = null
    for k, v of sketch.config.sketch.files
      m = k.match(/^(.+)\.rb$/)
      if m
        name = "#{m[1]}.mrb"
        break
    return callback?(false) unless name
    @activate((result) =>
      unless result
        callback?(false)
        return
      setup = (callback) -> callback(true)
      # unless @temporary.setup_done
      #   setup = (callback) =>
      #     @_writeFile("wrbb.mrb", WRBB_MRB_DATA, (result) =>
      #       @temporary.setup_done = result
      #       callback(result)
      #     )
      FileUtil.readArrayBuf(
        [sketch.dirEntry, name]
        (result, readdata) =>
          return callback?(false) unless result
          setup((result) =>
            return callback?(false) unless result
            @_writeFile(name, readdata, (result) =>
              return callback?(false) unless result
              @downloaded_name = name
              callback?(true)
            )
          )
      ) # FileUtil.readArrayBuf
    ) # @activate
    return

  run: (callback) ->
    printSerial = =>
      @connection.read("\r\n".toUint8Array(), (token) =>
        token = token.toUtf8String()
        if token == "#{@version_line}\r\n"
          App.stdout("[Finish #{@downloaded_name}]\r\n")
          Board.uiChangeButtonState(true)
          return
        App.stdout(token)
        printSerial()
      )
    return callback?(false) unless @downloaded_name
    Board.uiChangeButtonState(false)
    window.setTimeout(
      =>
        @_command("R #{@downloaded_name}", (result) =>
          return callback?(false) unless result
          @connection.setPollByte()
          App.stdout("[Run #{@downloaded_name}]\r\n")
          printSerial()
          callback?(true)
        )
      500
    )
    return

  stop: (callback) ->
    @getInfo((result) =>
      callback?(result)
    )
    return

