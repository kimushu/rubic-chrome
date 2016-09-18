"use strict"
# Pre dependencies
Board = require("board/board")
I18n = require("util/i18n")
AsyncFs = require("filesystem/asyncfs")
Programmer = require("programmer/programmer")
require("util/primitive")

###*
@class PeridotBoard
  PERIDOT board (Model)
@extends Board
###
module.exports = class PeridotBoard extends Board
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
  @classProperty("id", value: "016baa35-4954-4b47-89c2-4d379c314f1d")

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
  @classProperty("friendlyName", value: new I18n("PERIDOT"))

  ###*
  @static
  @property {I18n} author
    Author of this board class
  @readonly
  ###
  @classProperty("author", value: new I18n("J-7SYSTEM WORKS"))

  ###*
  @static
  @property {string} website
    Website URL of this board class
  @readonly
  ###
  @classProperty("website", value: "https://osafune.github.io/peridot.html")

  ###*
  @static
  @property {string[]} images
    List of images of this board class
    (The first item is used as an icon)
  @readonly
  ###
  @classProperty("images", get: -> [
    "images/boards/peridot_64x64.png"
  ])

  ###*
  @static
  @property {string[]} boardRevisions
    List of board revisions of this board class
  @readonly
  ###
  @classProperty("boardRevisions", get: -> [
    "VER 1.0 / VER 1.1"
  ])

  #--------------------------------------------------------------------------------
  # Private constants
  #

  FPGAPIN = new I18n({en: "Pin name of FPGA", ja: "FPGAピン名"})

  VID_PID_LIST = [
    # VID)PID)
    0x04036015  # FTDI FT240X
  ]

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
  @inheritdoc Board#getProgrammer
  ###
  getProgrammer: ->
    return new PeridotProgrammer(@_canarium)

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
    return Canarium.enumerate().then((boards) ->
      devices = []
      for device in boards
        if Preferences.os == "mac" and device.path.startsWith("/dev/tty.")
          continue  # Drop TTY device (for Mac)
        id = (parseInt(device.vendorId) << 16) + parseInt(device.productId)
        devices.push({
          friendlyName: device.name
          path: device.path
          productId: device.productId
          vendorId: device.vendorId
          hidden: !VID_PID_LIST.includes(id)
        })
      return devices
    )

  ###*
  @inheritdoc Board#connect
  ###
  connect: (path) ->
    return @_canarium.open(path).then(=>
      @_canarium.onClosed = =>
        @_canarium.onClosed = null
        @_connected = false
        @dispatchEvent({type: "disconnect"})

      @_connected = true
      @dispatchEvent({type: "connect"})
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
  requestFileSystem: (storage) ->
    return new PeridotFileSystem(@_canarium, "/mnt/#{storage}")

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

    ###*
    @inheritdoc AsyncFs#getNameImpl
    ###
    getNameImpl: ->
      return @_dir

    ###*
    @inheritdoc AsyncFs#readFileImpl
    ###
    readFileImpl: (path, options) ->
      return

    ###*
    @inheritdoc AsyncFs#writeFileImpl
    ###
    writeFileImpl: (path, data, options) ->
      return

    ###*
    @inheritdoc AsyncFs#unlinkImpl
    ###
    unlinkImpl: (path) ->
      return

    ###*
    @inheritdoc AsyncFs#opendirfsImpl
    ###
    opendirfsImpl: (path) ->
      return

    ###*
    @method constructor
      Constructor of PeridotFileSystem class
    ###
    constructor: (@_canarium, @_dir) ->
      super(AsyncFs.BOARD_INTERNAL)
      return

  class PeridotProgrammer extends Programmer
    null

    constructor: (@_canarium) ->
      return

# Post dependencies
Canarium = global.Libs.Canarium.Canarium
Preferences = require("app/preferences")
