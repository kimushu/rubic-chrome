"use strict"
# Pre dependencies
Board = require("board/board")
I18n = require("util/i18n")
AsyncFs = require("filesystem/asyncfs")
BoardConsole = require("board/boardconsole")
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

  PERIDOT_HTTP_TIMEOUT = 3000
  SERVER_HOST         = "peridot"
  SERVER_FS_PATH      = "/mnt/epcs"

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
    @_canarium.onClosed = =>
      Promise.delay(0).then(=>
        PeridotBoard.__super__.disconnect.call(this)
        return
      )
    return

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
    return @errorConnected() if @_canarium.connected
    return @_canarium.open(path).then(=>
      @irqBase = @nextTxPacket = @nextRxPacket = null
      return super(path)
    ) # return @_canarium.open().then()

  ###*
  @inheritdoc Board#disconnect
  ###
  disconnect: ->
    return @errorNotConnected() unless @_canarium.connected
    return @_canarium.close()

  ###*
  @inheritdoc Board#getBoardInfo
  ###
  getBoardInfo: ->
    return @errorNotConnected() unless @_canarium.connected
    return Promise.resolve(
    ).then(=>
      return @_canarium.getinfo()
    )

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
        return Promise.resolve(new PeridotFileSystemLegacy(this))
    return Promise.reject(Error("Unknown storage"))

  ###*
  @inheritdoc Board#startSketch
  ###
  startSketch: (onFinished) ->
    return new Promise((resolve, reject) =>
      req = @_newHttpRequest()
      req.timeout = PERIDOT_HTTP_TIMEOUT
      req.onreadystatechange = =>
        return unless req.readyState == req.DONE
        return resolve() unless req.errorFlag
        return reject()
      req.open("POST", "http://#{SERVER_HOST}/start")
      req.send()
    ).then(=>
      return new PeridotConsoleLegacy()
    ) # return new Promise().then()

  ###*
  @inheritdoc Board#stopSketch
  ###
  stopSketch: () ->
    return new Promise((resolve, reject) =>
      req = @_newHttpRequest()
      req.timeout = PERIDOT_HTTP_TIMEOUT
      req.onreadystatechange = =>
        return unless req.readyState == req.DONE
        return resolve() unless req.errorFlag
        return reject()
      req.open("POST", "http://#{SERVER_HOST}/stop")
      req.send()
    ) # return new Promise()

  #--------------------------------------------------------------------------------
  # Private methods
  #

  ###*
  @private
  @method _newHttpRequest
  Make new XMLHttpRequest compatible object (for legacy I/F)
  ###
  _newHttpRequest: ->
    return new MemHttpRequest(this)

  DEBUG               = 0
  MEM_BASE            = 0xfffc000
  MEM_HTTP_SIGNATURE  = "MHttp1.0"
  MEM_HTTP_VALID      = 1
  MEM_HTTP_SOM        = 2
  MEM_HTTP_EOM        = 4

  ###*
  @method getTxPacket
  Get next empty TX packet
  ###
  getTxPacket: (callback) ->
    @connectDataLink((result) =>
      return callback?(null) unless result
      base = @nextTxPacket
      @_canarium.avm.read(base, 8, (result, readdata) =>
        return callback?(null) unless result
        header = new Uint8Array(readdata)
        flags = (header[5] << 8) | header[4]
        return callback?(null) unless (flags & MEM_HTTP_VALID) == 0
        packet =
          capacity: (header[3] << 8) | header[2]
          startOfMessage: null
          endOfMessage: null
          length: null
          buffer: null
          transmit: (tx_callback) ->
            App.log.verbose({tx_packet1: {base: base, data: @buffer}}) if DEBUG > 0
            @peridot._canarium.avm.write(base + 8, @buffer, (result) =>
              return tx_callback?(false) unless result
              word = (@length << 16) | MEM_HTTP_VALID
              word |= MEM_HTTP_SOM if @startOfMessage
              word |= MEM_HTTP_EOM if @endOfMessage
              @peridot._canarium.avm.iowr(base, 1, word, (result) =>
                return tx_callback?(false) unless result
                App.log.verbose({tx_packet2: {base: base, flags: word & 0xffff, length: word >> 16}}) if DEBUG > 0
                @peridot.raiseIrq((result) => tx_callback?(result))
              )
            )
          peridot: this
        @nextTxPacket = MEM_BASE + ((header[1] << 8) | header[0])
        App.log.verbose({tx_packet0: {base: base, packet: packet}}) if DEBUG > 0
        callback?(packet)
      )
    )

  ###*
  @method getRxPacket
  Get next full RX packet
  ###
  getRxPacket: (callback) ->
    @connectDataLink((result) =>
      return callback?(null) unless result
      base = @nextRxPacket
      @_canarium.avm.read(base, 8, (result, readdata) =>
        return callback?(null) unless result
        header = new Uint8Array(readdata)
        flags = (header[5] << 8) | header[4]
        length = (header[7] << 8) | header[6]
        return callback?(null) unless (flags & MEM_HTTP_VALID) != 0
        @_canarium.avm.read(base + 8, length, (result, readdata) =>
          return callback?(null) unless result
          packet =
            capacity: (header[3] << 8) | header[2]
            startOfMessage: (flags & MEM_HTTP_SOM) != 0
            endOfMessage: (flags & MEM_HTTP_EOM) != 0
            length: length
            buffer: readdata
            discard: (rx_callback) ->
              @peridot._canarium.avm.iowr(base, 1, 0, (result) =>
                return rx_callback?(false) unless result
                App.log.verbose({rx_packet1: {base: base, discarded: true}}) if DEBUG > 0
                @peridot.raiseIrq((result) => rx_callback?(result))
              )
            peridot: this
          @nextRxPacket = MEM_BASE + ((header[1] << 8) | header[0])
          App.log.verbose({rx_packet0: {base: base, packet: packet}}) if DEBUG > 0
          callback?(packet)
        )
      )
    )

  ###*
  @private
  @method connectDataLink
  ###
  connectDataLink: (callback) ->
    return callback?(true) if @irqBase? and @nextTxPacket? and @nextRxPacket?
    @_canarium.avm.read(MEM_BASE, 16, (result, readdata) =>
      return callback?(false) unless result
      sign = String.fromCharCode.apply(null, new Uint8Array(readdata.slice(0, 8)))
      return callback?(false) unless sign == MEM_HTTP_SIGNATURE
      array = new Uint8Array(readdata)
      @irqBase = (array[11] << 24) | (array[10] << 16) | (array[9] << 8) | array[8]
      @nextTxPacket = MEM_BASE + ((array[13] << 8) | array[12])
      @nextRxPacket = MEM_BASE + ((array[15] << 8) | array[14])
      App.log.verbose({datalink: {irq_base: @irqBase, tx_packet: @nextTxPacket, rx_packet: @nextRxPacket}}) if DEBUG > 0
      callback?(true)
    )

  ###*
  @private
  @method raiseIrq
  ###
  raiseIrq: (callback) ->
    return callback?(false) unless @irqBase?
    return callback?(true) if @irqBase == 0
    @_canarium.avm.iowr(@irqBase, 0, 1, (result) ->
      App.log.verbose({raise_irq: result}) if DEBUG > 0
      callback?(result)
    )

  #--------------------------------------------------------------------------------
  # Internal class
  #

  class PeridotFileSystemLegacy extends AsyncFs
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
      if path == "main.mrb"
        return Promise.resolve(new ArrayBuffer(0))
      return super(path, options)

    ###*
    @inheritdoc AsyncFs#writeFileImpl
    ###
    writeFileImpl: (path, data, options) ->
      if path == "main.mrb"
        return new Promise((resolve, reject) =>
          req = @_peridot._newHttpRequest()
          req.timeout = PERIDOT_HTTP_TIMEOUT
          req.onreadystatechange = =>
            return unless req.readyState == req.DONE
            return resolve() unless req.errorFlag
            return reject()
          req.open("PUT", "http://#{SERVER_HOST}#{SERVER_FS_PATH}/#{path}")
          req.send(new Uint8Array(data))
        ) # return new Promise()
      return super(path, data, options)

    # ###*
    # @inheritdoc AsyncFs#unlinkImpl
    # ###
    # unlinkImpl: (path) ->
    #   return super(path)

    # ###*
    # @inheritdoc AsyncFs#opendirfsImpl
    # ###
    # opendirfsImpl: (path) ->
    #   return super(path)

    ###*
    @method constructor
      Constructor of PeridotFileSystem class
    ###
    constructor: (@_peridot) ->
      super(AsyncFs.BOARD_INTERNAL)
      return

  class PeridotConsoleLegacy extends BoardConsole
    open: ->
      Promise.delay(1).then(=>
        @close()
      )
      return Promise.resolve()

    send: (data) ->
      return Promise.resolve()

    close: ->
      @dispatchEvent({type: "close.console", board: @_wrbb})
      return Promise.resolve()

# Post dependencies
MemHttpRequest = require("./memhttprequest")
Canarium = global.Libs.Canarium.Canarium
Preferences = require("app/preferences")
