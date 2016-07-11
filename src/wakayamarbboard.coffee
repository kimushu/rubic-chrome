# Dependencies
Board = require("./board")
I18n = require("./i18n")
AsyncFs = require("./asyncfs")
ab2str = require("./ab2str")
str2ab = require("./str2ab")

###*
@class WakayamaRbBoard
  Wakayama.rb board (Model)
@extends Board
###
class WakayamaRbBoard extends Board
  Board.jsonable(this)

  #--------------------------------------------------------------------------------
  # Public properties
  #

  ###*
  @static
  @property {I18n}
    Name of this board
  @readonly
  ###
  @friendlyName: new I18n({
    en: "Wakayama.rb board"
    ja: "Wakayama.rb ボード"
  })

  ###*
  @static
  @property {I18n}
    Author of this board
  @readonly
  ###
  @author: new I18n(
    "Minao Yamamoto"
  )

  ###*
  @static
  @property {string}
    Website URL of board
  @readonly
  ###
  @website: "https://github.com/tarosay/Wakayama-mruby-board"

  ###*
  @static
  @property {I18n}
    Description of this board
  @readonly
  ###
  @description: new I18n({
    # TODO
    "en": "Compact RX63N microcontroller board with Ruby language support and Arduino-like methods."
    "ja": "Arduinoに似たメソッドを持ち、Ruby言語でプログラミングができるコンパクトなRX63Nマイコンボード。"
  })

  ###*
  @static
  @property {string[]}
    List of images of this board (The first item is used as an icon)
  @readonly
  ###
  @images: ["images/boards/wrbb_64x64.png"]

  ###*
  @static
  @property {string}
    Rubic version
  @readonly
  ###
  @rubicVersion: ">= 1.0.0"

  #--------------------------------------------------------------------------------
  # Private variables / constants
  #

  CMD_TIMEOUT_MS      = 200
  READ1K_TIMEOUT_MS   = 500
  WRITE1K_TIMEOUT_MS  = 2000
  DELETE_TIMEOUT_MS   = 1000

  #--------------------------------------------------------------------------------
  # Public methods
  #

  ###*
  @inheritdoc Board#enumerate
  ###
  enumerate: ->
    return Promise.resolve(
    )

  ###*
  @inheritdoc Board#connect
  ###
  connect: (path) ->
    return Promise.resolve(
    )

  ###*
  @inheritdoc Board#disconnect
  ###
  disconnect: ->
    return Promise.resolve(
    )

  getStorages: ->
    return Promise.resolve(["internal"])

  ###*
  @inheritdoc Board#requestFileSystem
  ###
  requestFileSystem: (storage) ->
    return

  #--------------------------------------------------------------------------------
  # Private methods
  #

  _lock: (obj) ->
    return

  _unlock: (obj) ->
    return

  _send: (data) ->
    return

  _wait: (expect) ->
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
    HEX2BIN[i+0x30] = i for i in [0...10] by 1
    HEX2BIN[i+0x37] = i for i in [10...16] by 1

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
      path = path.replace(/\/\+/g, '/').replace(/\/$/, '')
      return Promise.reject(Error("invalid path")) if path == "" or path.includes(" ")
      return Promise.resolve(new @constructor(@_wrbb, "#{@_dir}#{path}/"))

  #--------------------------------------------------------------------------------
  #--------------------------------------------------------------------------------
  #--------------------------------------------------------------------------------
  #--------------------------------------------------------------------------------
  #--------------------------------------------------------------------------------
  #--------------------------------------------------------------------------------
  # Private constants
  #

  SerialPort = null
  TOL5V = new I18n({en: "5V tolerant", ja: "5Vトレラント"})
  ADPIN = new I18n({en: "With analog input", ja: "アナログ入力対応"})
  DAPIN = new I18n({en: "With analog output", ja: "アナログ出力対応"})
  RXPIN = new I18n({en: "Pin name of RX63N", ja: "RX63Nピン名"})
  ANPIN = new I18n({en: "Analog pins", ja: "アナログ対応ピン名"})

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
    SerialPort or= Canarium.BaseComm.SerialWrapper
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
    return SerialPort.list().then((ports) ->
      getFriendlyName = (port) ->
        name = port.manufacturer
        path = port.path
        return "#{name} (#{path})" if name? and name != ""
        return path
      return {friendlyName: getFriendlyName(p), path: p.path} for p in ports
    )

  ###*
  @inheritdoc Board#connect
  ###
  connect: (path, onDisconnected) ->
    @_serial = new SerialPort(path)
    return @_serial.open().then(=>
      @_serial.onClosed = =>
        @_serial.onClosed = null
        @_connected = false
        onDisconnected()

      @_connected = true
      return
    ) # return @_serial.open().then()

  ###*
  @inheritdoc Board#disconnect
  ###
  disconnect: ->
    return @_serial.close().then(=>
      @_serial = null
      return
    )

module.exports = WakayamaRbBoard

# Post dependencies
# (none)
