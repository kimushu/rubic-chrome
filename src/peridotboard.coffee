# Pre dependencies
Board = require("./board")
I18n = require("./i18n")
AsyncFs = require("./asyncfs")

###*
@class PeridotBoard
  PERIDOT board (Model)
@extends Board
###
class PeridotBoard extends Board
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
  @friendlyName: new I18n(
    "PERIDOT"
  )

  ###*
  @static
  @property {I18n}
    Author of this board
  @readonly
  ###
  @author: new I18n(
    "J-7SYSTEM WORKS"
  )

  ###*
  @static
  @property {string}
    Website URL of this board
  @readonly
  ###
  @website: "https://osafune.github.io/peridot.html"

  ###*
  @static
  @property {I18n}
    Description of this board
  @readonly
  ###
  @description: new I18n({
    "en": "FPGA-based Arduino form-factor board with configurable hardware. This board supports many script engines such as mruby, Lua, Javascript, and so on."
    "ja": "ハードウェア構成をカスタマイズできるFPGA搭載のArduino互換形状ボード。スクリプト言語エンジンにはmruby/Lua/JavaScriptなど様々な種類から選択できます。"
  })

  ###*
  @static
  @property {string[]}
    List of images of this board (The first item is used as an icon)
  @readonly
  ###
  @images: ["images/boards/peridot_64x64.png"]

  ###*
  @static
  @property {string}
    Rubic version
  @readonly
  ###
  @rubicVersion: ">=1.0.0"

  ###*
  @static
  @property {string[]}
    List of board variations
  @readonly
  ###
  @boardVariations: []

  #--------------------------------------------------------------------------------
  # Private constants
  #

  FPGAPIN = new I18n({en: "Pin name of FPGA", ja: "FPGAピン名"})

  #--------------------------------------------------------------------------------
  # Public methods
  #

  ###*
  @method constructor
    Constructor of PeridotBoard class
  @param {Object} obj
    JSON object
  ###
  constructor: (obj) ->
    super(obj)
    @_canarium = new Canarium()
    return

  ###*
  @inheritdoc Board#getEngineList
  ###
  getEngineList: ->
    return [
      {
        name: "mruby"
        id: "mruby"
        icon: "mruby"
      }
      {
        name: "Duktape (JavaScript / CoffeeScript)"
        id: "duktape"
        icon: "javascript"
        beta: true
      }
      {
        name: "Lua"
        id: "lua"
        icon: "lua"
        beta: true
      }
      {
        name: "MicroPython"
        id: "micropython"
        icon: "python"
        beta: true
      }
    ] # return []

  ###*
  @inheritdoc Board#getPinList
  ###
  getPinList: ->
    return {
      left: [
        {}
        {}
        {}
        {private: "NC"}
        {private: "IOREF"}
        {private: "RESET"}
        {private: "3.3V"}
        {private: "VBUS"}
        {private: "GND"}
        {private: "GND"}
        {private: "NC"}
        {}
        {name: "D16", aliases: ["PIN_42"]}
        {name: "D17", aliases: ["PIN_43"]}
        {name: "D18", aliases: ["PIN_46"]}
        {name: "D19", aliases: ["PIN_51"]}
        {name: "D20", aliases: ["PIN_52"]}
        {name: "D21", aliases: ["PIN_53"]}
        {}
        {name: "D22", aliases: ["PIN_54"]}
        {name: "D23", aliases: ["PIN_55"]}
        {name: "D24", aliases: ["PIN_64"]}
        {name: "D25", aliases: ["PIN_65"]}
        {name: "D26", aliases: ["PIN_77"]}
        {name: "D27", aliases: ["PIN_80"]}
      ]
      right: [
        {name: "D15", aliases: ["PIN_3"]}
        {name: "D14", aliases: ["PIN_2"]}
        {private: "NC"}
        {private: "GND"}
        {name: "D13", aliases: ["PIN_1"]}
        {name: "D12", aliases: ["PIN_144"]}
        {name: "D11", aliases: ["PIN_143"]}
        {name: "D10", aliases: ["PIN_142"]}
        {name: "D9",  aliases: ["PIN_141"]}
        {name: "D8",  aliases: ["PIN_136"]}
        {}
        {name: "D7",  aliases: ["PIN_129"]}
        {name: "D6",  aliases: ["PIN_128"]}
        {name: "D5",  aliases: ["PIN_115"]}
        {name: "D4",  aliases: ["PIN_87"]}
        {name: "D3",  aliases: ["PIN_86"]}
        {name: "D2",  aliases: ["PIN_85"]}
        {name: "D1",  aliases: ["PIN_84"]}
        {name: "D0",  aliases: ["PIN_83"]}
      ]
      aliases: [FPGAPIN]
      image: {
      }
    } # return {}

  ###*
  @inheritdoc Board#enumerate
  ###
  enumerate: ->
    return @_canarium.enumerate().then((boards) ->
      return {friendlyName: b.name, path: b.path} for b in boards
    )

  ###*
  @inheritdoc Board#connect
  ###
  connect: (path, onDisconnected) ->
    return @_canarium.open(path).then(=>
      @_canarium.onClosed = =>
        @_canarium.onClosed = null
        @_connected = false
        onDisconnected()

      @_connected = true
      return
    ) # return @_canarium.open().then()

  ###*
  @inheritdoc Board#disconnect
  ###
  disconnect: ->
    return @_canarium.close()

  ###*
  @inheritdoc Board#requestFileSystem
  ###
  requestFileSystem: ->
    return new PeridotFileSystem(@_canarium)

  ###*
  @inheritdoc Board#requestConsole
  ###
  requestConsole: ->
    return @_canarium.requestSerial()

  ###*
  @inheritdoc Board#startSketch
  ###
  startSketch: (onFinished) ->
    # return @_canarium.
    return

  #--------------------------------------------------------------------------------
  # Internal class
  #

  class PeridotFileSystem extends AsyncFs
    null

    constructor: (@_canarium) ->
      return

    readFile: (file, options, callback) ->
      if typeof(options or= {}) == "function"
        callback = options
        options = {}

module.exports = PeridotBoard

# Post dependencies
Canarium = global.Canarium
