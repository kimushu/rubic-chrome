"use strict"
# Pre dependencies
Board = require("board/board")
I18n = require("util/i18n")
AsyncFs = require("filesystem/asyncfs")
ab2str = require("util/ab2str")
str2ab = require("util/str2ab")
require("util/primitive")

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
  READ1K_TIMEOUT_MS   = 500
  WRITE1K_TIMEOUT_MS  = 2000
  DELETE_TIMEOUT_MS   = 1000

  VID_PID_LIST = [
    # VID)PID)
    0x21290531  # Tokuden driver
    0x045b0234  # Renesas driver
  ]

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
        id = (parseInt(port.vendorId) << 16) + parseInt(port.productId)
        devices.push({
          friendlyName: port.manufacturer
          path: port.path
          productId: port.productId
          vendorId: port.vendorId
          hidden: !VID_PID_LIST.includes(id)
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
      serial.onClosed = @_closeHandler.bind(this)
      serial.onReceived = @_receiveHandler.bind(this)
      @_serial = serial
      @_path = path
      @dispatchEvent({type: "connect.board"})
      return  # Last PromiseValue
    )

  ###*
  @inheritdoc Board#disconnect
  ###
  disconnect: ->
    return @errorNotConnected() unless @_serial?
    return @_serial.close().then(=>
      @_serial = null
      return  # Last PromiseValue
    )

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
      return @_wait("(H [ENTER])").timeout(CMD_TIMEOUT_MS)
    ).then((readdata) =>
      return ab2str(readdata)
    ).then((readdata) =>
      v = readdata.split("\r").pop().match(/^(.+)(Ver\..+)\(H \[ENTER\]\)/)
      return {
        path: @_path
        firmware: v[1].trim?()
        firmRevision: v[2].trim?()
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

  # requestConsole

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
      return @_send("R #{target}\r")
    ).then(=>
      return @_wait(">R #{target}\r")
    ).then(=>
      return @_unlock(lock)
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
  @param {string/ArrayBuffer} expect
    Wait data
  @return {Promise}
    Promise object
  @return {ArrayBuffer} return.PromiseValue
    Received data
  ###
  _wait: (expect) ->
    return Promise.reject(Error("Already waiting")) if @_waiter?
    return Promise.resolve(
    ).then(=>
      App.log.verbose("WakayamaRbBoard#_wait(%o)", expect)
      return str2ab(expect) if typeof(expect) == "string"
      return expect
    ).then((ab) =>
      return new Promise((resolve, reject) =>
        @_waiter = {token: new Uint8Array(ab), resolve: resolve, reject: reject}
      )
    ) # return Promise.resolve().then()...

  ###*
  @private
  @method
    Handler for disconnection
  ###
  _closeHandler: ->
    @_serial = null
    reject = @_waiter?.reject
    @_waiter = null
    reject?()
    @dispatchEvent({type: "disconnect.board"})
    return

  ###*
  @private
  @method
    Handler for data receive
  @param {ArrayBuffer} ab
    Received data
  ###
  _receiveHandler: (ab) ->
    App.log.verbose("WakayamaRbBoard#_recv(%o)", ab)
    @_recvBuffer or= new FifoBuffer()
    oldLen = @_recvBuffer.byteLength
    @_recvBuffer.push(ab)
    token = @_waiter?.token
    return unless token?
    tlen = token.byteLength
    start = Math.max(0, oldLen - tlen)
    end = @_recvBuffer.byteLength - tlen
    return unless start <= end
    data = new Uint8Array(@_recvBuffer.peek())
    for i in [start..end] by 1
      match = true
      for j in [0...tlen] by 1
        if data[i+j] != token[j]
          match = false
          break
      continue unless  match
      data = @_recvBuffer.pop(i + tlen)
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
        return @_wrbb._send("F #{@dir}#{path}\r")
      ).then(=>
        return @_wrbb._wait("\rWaiting").timeout(CMD_TIMEOUT_MS)
      ).then(=>
        return @_wrbb._send("\r")
      ).then(=>
        return @_wrbb._wait("\rWaiting").timeout(CMD_TIMEOUT_MS)
      ).then((readdata) =>
        text = String.fromCharCode.apply(null, new Uint8Array(readdata))
        text.match(/\r(\d+)\rWaiting/, (match, sizeLine) =>
          result = new Uint8Array(parseInt(sizeLine))
        )
        return @_wrbb._send("\r")
      ).then(=>
        return @_wrbb._wait("\r").timeout(CMD_TIMEOUT_MS)
      ).then(=>
        return @_wrbb._wait("\r").timeout(READ1K_TIMEOUT_MS * ((length + 1024) / 1024))
      ).then((readdata) =>
        src = new Uint8Array(readdata)
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
        return @_wrbb._send("U #{@_dir}#{path} #{src.byteLength * 2}\r")
      ).then(=>
        return @_wrbb._wait("\rWaiting").timeout(CMD_TIMEOUT_MS)
      ).then(=>
        dump = ""
        for i in [0...src.byteLength] by 1
          dump += "0#{i.toString(16).toUpperCase()}".substr(-2)
        return @_wrbb._send(dump)
      ).then(=>
        return @_wrbb._wait("Saving").timeout(CMD_TIMEOUT_MS)
      ).then(=>
        return @_wrbb._wait("\r\r").timeout(
          WRITE1K_TIMEOUT_MS * ((src.byteLength + 1024) / 1024)
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
        return @_wrbb._wait("\r\r").timeout(DELETE_TIMEOUT_MS)
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
      super(AsyncFs.BOARD_INTERNAL)
      return

# Post dependencies
App = require("app/app")
FifoBuffer = require("util/fifobuffer")
Preferences = require("app/preferences")
Canarium = global.Libs.Canarium.Canarium
SerialPort = Canarium.BaseComm.SerialWrapper
