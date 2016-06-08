# Dependencies
Board = require("./board")
I18n = require("./i18n")

AsyncFs = {}

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
    "ja": "Arduinoに似たメソッドを持ちつつ、Ruby言語でプログラミングができるコンパクトなRX63N搭載マイコンボード。"
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

  ###*
  @static
  @property {Object[]}
    List of board variations
  @readonly
  ###
  @board: []

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

  ###*
  @inheritdoc Board#requestFileSystem
  ###
  requestFileSystem: ->
    return new WrbbFileSystem(@_serial)

  ###*
  @inheritdoc Board#requestConsole
  ###
  requestConsole: ->
    return # FIXME

  #--------------------------------------------------------------------------------
  # Internal class
  #

  class WrbbFileSystem extends AsyncFs
    null

    constructor: (@_serial) ->
      return

