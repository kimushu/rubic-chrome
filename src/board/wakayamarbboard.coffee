"use strict"
# Pre dependencies
Board = require("board/board")
I18n = require("util/i18n")
AsyncFs = require("filesystem/asyncfs")
BoardConsole = require("board/boardconsole")
require("util/primitive")
require("compat/bbjscompat")

###*
@class WakayamaRbBoard
  Wakayama.rb board (Model)
@extends Board
###
module.exports = class WakayamaRbBoard extends Board
  Board.jsonable(this)

  #--------------------------------------------------------------------------------
  # Public properties
  #

  ###*
  @static
  @property {string} id
    ID of this board class
  @readonly
  ###
  @classProperty("id", value: "498d332f-0172-4797-8653-019d864159e8")

  ###*
  @static
  @property {string} rubicVersion
    Rubic version
  @readonly
  ###
  @classProperty("rubicVersion", value: ">= 0.9.0")

  ###*
  @static
  @property {I18n} friendlyName
    Name of this board class
  @readonly
  ###
  @classProperty("friendlyName", value: new I18n(
    en: "Wakayama.rb board"
    ja: "Wakayama.rb ボード"
  ))

  ###*
  @static
  @property {I18n} author
    Author of this board class
  @readonly
  ###
  @classProperty("author", value: new I18n("Minao Yamamoto"))

  ###*
  @static
  @property {string} website
    Website URL of board class
  @readonly
  ###
  @classProperty("website", value: "https://github.com/tarosay/Wakayama-mruby-board")

  ###*
  @static
  @property {string[]} images
    List of images of this board class
    (The first item is used as an icon)
  @readonly
  ###
  @classProperty("images", get: -> [
    "images/boards/wrbb_64x64.png"
  ])

  #--------------------------------------------------------------------------------
  # Private variables / constants
  #

  CMD_TIMEOUT_MS      = 200
  CMD_RETRIES         = 10
  READ1K_TIMEOUT_MS   = 1000
  WRITE1K_TIMEOUT_MS  = 2000
  DELETE_TIMEOUT_MS   = 1000
  V1_VERSION_NEEDLE   = "H [ENTER])"
  V1_VERSION_LINE     = /^(WAKAYAMA\.RB Board) Ver\.([^-]+)-([^,]+),([^(]+)\((?:help->)?H \[ENTER\]\)$/

  @VID_PID_LIST: [
    # VID)PID)
    0x21290531  # Tokuden driver
    0x045b0234  # Renesas driver
  ]

  @POLL_BY_FEH: 100   # Enable polling by 0xfe at 100ms intervals
  @BINARY_MODE: true

  TOL5V = new I18n({en: "5V tolerant", ja: "5Vトレラント"})
  ADPIN = new I18n({en: "With analog input", ja: "アナログ入力対応"})
  DAPIN = new I18n({en: "With analog output", ja: "アナログ出力対応"})
  RXPIN = new I18n({en: "Pin number of RX63N", ja: "RX63Nピン番号"})
  ANPIN = new I18n({en: "Analog pins", ja: "アナログピン名称"})

  #--------------------------------------------------------------------------------
  # Public methods
  #

  ###*
  @method constructor
    Constructor of WakayamaRbBoard class
  @param {Object} obj
    JSON object
  ###
  constructor: (obj) ->
    super(obj)
    return

  ###*
  @inheritdoc Board#getPinList
  ###
  getPinList: ->
    return {
      left: [
        {name: "0",   aliases: ["P20"], specials: [TOL5V]}
        {name: "1",   aliases: ["P21"], specials: [TOL5V]}
        {name: "18",  aliases: ["PC0"], specials: [TOL5V]}
        {name: "19",  aliases: ["PC1"], specials: [TOL5V]}
        {name: "2",   aliases: ["PC2"], specials: [TOL5V]}
        {name: "3",   aliases: ["P12"], specials: [TOL5V]}
        {name: "4",   aliases: ["P13"], specials: [TOL5V]}
        {name: "5",   aliases: ["P50"]}
        {name: "6",   aliases: ["P52"]}
        {name: "7",   aliases: ["P32"], specials: [TOL5V]}
        {name: "8",   aliases: ["P33"], specials: [TOL5V]}
        {name: "9",   aliases: ["P05","DA1"], specials: [DAPIN]}
      ]
      right: [
        {private: "5V"}
        {private: "GND"}
        {private: "RESET"}
        {private: "3.3V"}
        {name: "17",  aliases: ["P43","A3"], specials: [ADPIN]}
        {name: "16",  aliases: ["P42","A2"], specials: [ADPIN]}
        {name: "15",  aliases: ["P41","A1"], specials: [ADPIN]}
        {name: "14",  aliases: ["P40","A0"], specials: [ADPIN]}
        {name: "13",  aliases: ["PC5"]}
        {name: "12",  aliases: ["PC7"]}
        {name: "11",  aliases: ["PC6"]}
        {name: "10",  aliases: ["PC4"]}
      ]
      aliases: [RXPIN, ANPIN]
      image: {
      }
    } # return {}

  ###*
  @inheritdoc Board#enumerate
  ###
  enumerate: ->
    return SerialPort.list().then((ports) =>
      devices = []
      for port in ports
        if Preferences.os == "mac" and port.path.startsWith("/dev/tty.")
          continue  # Drop TTY device (for Mac)
        id = ((parseInt(port.vendorId) << 16) + parseInt(port.productId)) >>> 0
        devices.push({
          friendlyName: port.manufacturer
          path: port.path
          productId: port.productId
          vendorId: port.vendorId
          hidden: !@constructor.VID_PID_LIST.includes(id)
        })
      return devices
    )

  ###*
  @inheritdoc Board#connect
  ###
  connect: (path) ->
    return @errorConnected() if @_serial?
    serial = new SerialPort(path)
    return serial.open().then(=>
      serial.onClosed = =>
        Promise.delay(0).then(=>
          @_closeHandler()
          return
        )
      serial.onReceived = (data) =>
        Promise.delay(0).then(=>
          @_receiveHandler(data)
          return
        )
      @_serial = serial
      return super(path)
    ) # return serial.open().then()

  ###*
  @inheritdoc Board#disconnect
  ###
  disconnect: ->
    oldSerial = @_serial
    return @errorNotConnected() unless oldSerial?
    @_serial = null
    return Promise.resolve(
    ).then(=>
      return oldSerial.close?()
    ).then(=>
      return super()
    ).catch((error) =>
      @_serial = oldSerial
      return Promise.reject(error)
    ) # return Promise.resolve().then()...

  ###*
  @inheritdoc Board#getBoardInfo
  ###
  getBoardInfo: ->
    return @errorNotConnected() unless @_serial?
    lock = {}
    return Promise.resolve(
    ).then(=>
      return @_lock(lock)
    ).then(=>
      return @_send("H\r")
    ).then(=>
      return @_pull(@_wait(V1_VERSION_NEEDLE))
    ).then((readdata) =>
      return ab2str(readdata)
    ).then((readdata) =>
      verline = readdata.split("\r\n").pop()
      App.log("WakayamaRbBoard#getBoardInfo: (%o)", verline)
      v = verline.match(V1_VERSION_LINE)
      return Promise.reject(Error("Bad response")) unless v?
      return {
        "{Kind_of_board}": v[2]?.trim()
        "{Firmware_revision}": v[3]?.trim()
        "{Embedded_script_engine}": v[4]?.trim()
      } # Last PromiseValue
    ).finally(=>
      return @_unlock(lock)
    ) # return Promise.resolve().then()...

  ###*
  @inheritdoc Board#getStorages
  ###
  getStorages: ->
    return Promise.resolve(["internal"])

  ###*
  @inheritdoc Board#requestFileSystem
  ###
  requestFileSystem: (storage) ->
    switch storage
      when "internal"
        return Promise.resolve(new WrbbFileSystemV1(this))
    return Promise.reject(Error("invalid storage: `#{storage}'"))

  ###*
  @inheritdoc Board#startSketch
  ###
  startSketch: (target, onFinished) ->
    return @errorNotConnected() unless @_serial?
    lock = {}
    return Promise.resolve(
    ).then(=>
      return @_lock(lock)
    ).then(=>
      return @_send("\bR #{target}\r")
    ).then(=>
      return @_wait("\bR #{target}\r\n")
    ).then(=>
      return @_unlock(lock)
    ).then(=>
      return new WrbbConsoleV1(this, onFinished)
    )
    return

  #--------------------------------------------------------------------------------
  # Private methods
  #

  ###*
  @private
  @method
    Lock communication
  @param {Object} obj
    Lock object
  @return {Promise}
    Promise object
  ###
  _lock: (obj) ->
    return new Promise((resolveLock) =>
      @_lockPromise = (@_lockPromise or Promise.resolve()).then(=>
        @_waiter = null
        resolveLock()
        return new Promise((resolveUnlock) =>
          obj.unlock = resolveUnlock
        )
      )
    ) # return new Promise()

  ###*
  @private
  @method
    Unlock communication
  @param {Object} obj
    Lock object
  @return {Promise}
    Promise object
  ###
  _unlock: (obj) ->
    reject = @_waiter?.reject
    @_waiter = null
    reject?()
    unlock = obj.unlock
    delete obj.unlock
    unlock()
    return Promise.resolve()

  ###*
  @private
  @method
    Send data
  @param {string/ArrayBuffer} data
    Data
  @return {Promise}
    Promise object
  ###
  _send: (data) ->
    return Promise.resolve(
    ).then(=>
      App.log.verbose("WakayamaRbBoard#_send(%o)", data)
      return str2ab(data) if typeof(data) == "string"
      return data
    ).then((ab) =>
      return @_serial.write(ab)
    ) # return Promise.resolve().then()...

  ###*
  @private
  @method
    Receive data
  @param {string/ArrayBuffer/number} expect
    Wait data or number of bytes
  @return {Promise}
    Promise object
  @return {ArrayBuffer} return.PromiseValue
    Received data
  ###
  _wait: (expect) ->
    return Promise.reject(Error("Already waiting")) if @_waiter?
    return Promise.resolve(
    ).then(=>
      if expect instanceof ArrayBuffer
        do ->
          except = except.slice(0)
          pro = null
          Object.defineProperty(except, "ab2str", get: -> pro or= ab2str(except))
      App.log.verbose("WakayamaRbBoard#_wait(%o)", expect)
      return str2ab(expect) if typeof(expect) == "string"
      return expect
    ).then((ab_len) =>
      token = new Uint8Array(ab_len) if ab_len instanceof ArrayBuffer
      length = ab_len if typeof(ab_len) == "number"
      return new Promise((resolve, reject) =>
        @_waiter = {token: token, length: length, resolve: resolve, reject: reject}
        @_receiveHandler(null)
      )
    ) # return Promise.resolve().then()...

  ###*
  @private
  @method
    Pull receive data by sending meaningless bytes
  ###
  _pull: (promise, timeout = CMD_TIMEOUT_MS, retries = CMD_RETRIES) ->
    timerId = global.setInterval((=> @_send(" \b")), timeout)
    return promise.timeout(timeout * (retries + 1)).finally(=>
      global.clearInterval(timerId)
    )

  ###*
  @private
  @method
    Handler for disconnection
  ###
  _closeHandler: ->
    reject = @_waiter?.reject
    @_waiter = null
    reject?()
    if @_serial?
      @_serial = {}
      @disconnect()
    return

  ###*
  @private
  @method
    Handler for data receive
  @param {ArrayBuffer} ab
    Received data
  ###
  _receiveHandler: (ab) ->
    if ab?.byteLength > 0
      do (ab) ->
        pro = null
        Object.defineProperty(ab, "ab2str", get: -> pro or= ab2str(ab))
        App.log.verbose("WakayamaRbBoard#_recv(%o, %i bytes)", ab, ab.byteLength)
      @_recvBuffer or= new FifoBuffer()
      @_recvBuffer.push(ab)
    tlen = @_waiter?.length
    if tlen?
      return if tlen < @_recvBuffer.byteLength
      data = @_recvBuffer.shift(tlen)
      resolve = @_waiter.resolve
      @_waiter = null
      resolve?(data)
      return
    token = @_waiter?.token
    return unless token?
    tlen = token.byteLength
    end = @_recvBuffer.byteLength - tlen
    return unless end >= 0
    start = @_waiter.nextScan or 0
    @_waiter.nextScan = start + 1
    data = new Uint8Array(@_recvBuffer.peek())
    for i in [start..end] by 1
      match = true
      for j in [0...tlen] by 1
        if data[i+j] != token[j]
          match = false
          break
      continue unless  match
      data = @_recvBuffer.shift(i + tlen)
      resolve = @_waiter.resolve
      @_waiter = null
      resolve?(data)
      break
    return

  #--------------------------------------------------------------------------------
  # Internal class
  #

  ###*
  @class WrbbFileSystemV1
    Pseudo filesystem for WakayamaRbBoard (V1 firmware)
  ###
  class WrbbFileSystemV1 extends AsyncFs
    null

    HEX2BIN = []
    (HEX2BIN[i+0x30] = i + 0) for i in [0...10] by 1
    (HEX2BIN[i+0x41] = i + 10) for i in [0...6] by 1
    (HEX2BIN[i+0x61] = i + 10) for i in [0...6] by 1
    BIN2HEX = ("0#{i.toString(16)}".substr(-2) for i in [0...256] by 1)

    ###*
    @inheritdoc AsyncFs#getNameImpl
    ###
    getNameImpl: ->
      return @_dir

    ###*
    @inheritdoc AsyncFs#readFileImpl
    ###
    readFileImpl: (path, options) ->
      result = null
      lock = {}
      return Promise.resolve(
      ).then(=>
        return @_wrbb._lock(lock)
      ).then(=>
        return @_wrbb._send("G #{@_dir}#{path}\r") if @_binaryMode
        return @_wrbb._send("F #{@_dir}#{path}\r")
      ).then(=>
        return @_wrbb._wait("\r\nWaiting").timeout(CMD_TIMEOUT_MS)
      ).then(=>
        return @_wrbb._send("\r")
      ).then(=>
        return @_wrbb._wait("\r\nWaiting").timeout(CMD_TIMEOUT_MS)
      ).then((readdata) =>
        text = String.fromCharCode.apply(null, new Uint8Array(readdata))
        text.replace(/\r\n(\d+)\r\nWaiting/, (match, sizeLine) =>
          result = new Uint8Array(parseInt(sizeLine))
        )
        return @_wrbb._send("\r")
      ).then(=>
        return @_wrbb._wait(result.byteLength) if @_binaryMode
        return @_wrbb._wait("\r\n").timeout(CMD_TIMEOUT_MS)
      ).then(=>
        return @_wrbb._wait("\r\n").timeout(READ1K_TIMEOUT_MS * ((length + 1024) / 1024))
      ).then((readdata) =>
        src = new Uint8Array(readdata)
        if @_binaryMode
          result.set(src)
        else
          for i in [0...result.byteLength] by 1
            byte = (HEX2BIN[src[i*2+0]] << 4) + (HEX2BIN[src[i*2+1]])
            return Promise.reject("Receive data error at byte ##{i}") if isNaN(byte)
            result[i] = byte
        return result.buffer unless options.encoding?   # Last PromiseValue (ArrayBuffer)
        return ab2str(result.buffer, options.encoding)  # Last PromiseValue (string)
      ).finally(=>
        return @_wrbb._unlock(lock)
      ) # return Promise.resolve().then()...

    ###*
    @inheritdoc AsyncFs#writeFileImpl
    ###
    writeFileImpl: (path, data, options) ->
      src = null
      lock = {}
      return Promise.resolve(
      ).then(=>
        return @_wrbb._lock(lock)
      ).then(=>
        return data unless options.encoding?
        return str2ab(data, options.encoding)
      ).then((buffer) =>
        src = new Uint8Array(buffer)
        return @_wrbb._send("W #{@_dir}#{path} #{src.byteLength}\r") if @_binaryMode
        return @_wrbb._send("U #{@_dir}#{path} #{src.byteLength * 2}\r")
      ).then(=>
        return @_wrbb._wait("\r\nWaiting").timeout(CMD_TIMEOUT_MS)
      ).then(=>
        if @_binaryMode
          dump = data
        else
          dump = ""
          for i in [0...src.byteLength] by 1
            dump += BIN2HEX[src[i]]
        return @_wrbb._send(dump)
      ).then(=>
        return @_wrbb._wait("Saving").timeout(WRITE1K_TIMEOUT_MS * ((src.byteLength + 1024) / 1024))
      ).then(=>
        return @_wrbb._pull(
          @_wrbb._wait("\r\n>")
          WRITE1K_TIMEOUT_MS
          ((src.byteLength + 1024) / 1024)
        )
      ).then(=>
        return  # Last PromiseValue
      ).finally(=>
        return @_wrbb._unlock(lock)
      ) # return Promise.resolve().then()...

    ###*
    @inheritdoc AsyncFs#unlinkImpl
    ###
    unlinkImpl: (path) ->
      lock = {}
      return Promise.resolve(
      ).then(=>
        return @_wrbb._lock(lock)
      ).then(=>
        return @_wrbb._send("D #{@_dir}#{path}\r")
      ).then(=>
        return @_wrbb._wait("\r\n\r\n").timeout(DELETE_TIMEOUT_MS)
      ).then(=>
        return  # Last PromiseValue
      ).finally(=>
        return @_wrbb._unlock(lock)
      ) # return Promise.resolve().then()...

    ###*
    @inheritdoc AsyncFs#opendirfsImpl
    ###
    opendirfsImpl: (path) ->
      path = path.replace(/\/\+/g, "/").replace(/\/$/, "")
      return Promise.reject(Error("invalid path")) if path == "" or path.includes(" ")
      return Promise.resolve(new @constructor(@_wrbb, "#{@_dir}#{path}/"))

    ###*
    @method constructor
      Constructor of WrbbFileSystemV1 class
    @param {WakayamaRbBoard} _wrbb
      Owner class instance
    @param {string} [_dir=""]
      Base directory
    ###
    constructor: (@_wrbb, @_dir = "") ->
      @_binaryMode = @_wrbb.constructor.BINARY_MODE
      super(AsyncFs.BOARD_INTERNAL)
      return

  ###*
  @class WrbbConsoleV1
    Pseudo filesystem for WakayamaRbBoard (V1 firmware)
  ###
  class WrbbConsoleV1 extends BoardConsole
    null

    ###*
    @method constructor
      Constructor of WrbbConsoleV1 class
    @param {WakayamaRbBoard} _wrbb
      Owner class instance
    @param {function(boolean)} _onClosed
      Close handler
    ###
    constructor: (@_wrbb, @_onClosed) ->
      super(@_wrbb)
      @_lock = {}
      @_opened = false
      return

    ###*
    @inheritdoc BoardConsole#open
    ###
    open: ->
      return Promise.reject(Error("Already opened")) if @_opened
      return @_wrbb._lock(@_lock).then(=>
        @_opened = true
        waitLoop = =>
          return @_wrbb._wait("\n").then((data) =>
            return unless @_opened
            return ab2str(data).then((text) =>
              if V1_VERSION_LINE.test(text.replace(/[\r\n]+$/, ""))
                onClosed = @_onClosed
                @_onClosed = null
                onClosed?(true)
                @close()
                return
              @dispatchEvent({type: "receive.console", board: @_wrbb, data: data})
              return waitLoop()
            ) # return ab2str().then()
          ) # return @_wrbb._wait().then()
        waitLoop()
        return
      )

    ###*
    @inheritdoc BoardConsole#send
    ###
    send: (data) ->
      return Promise.reject(Error("Not opened")) unless @_opened
      return @_wrbb._send(data)

    ###*
    @inheritdoc BoardConsole#close
    ###
    close: ->
      return Promise.reject(Error("Not opened")) unless @_opened
      @_opened = false
      @dispatchEvent({type: "close.console", board: @_wrbb})
      onClosed = @_onClosed
      @_onClosed = null
      onClosed?(false)
      return @_wrbb._unlock(@_lock)

# Post dependencies
ab2str = require("util/ab2str")
str2ab = require("util/str2ab")
App = require("app/app")
FifoBuffer = require("util/fifobuffer")
Preferences = require("app/preferences")
Canarium = global.Libs.Canarium.Canarium
SerialPort = Canarium.BaseComm.SerialWrapper
