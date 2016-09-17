"use strict"
# Pre dependencies
JSONable = require("util/jsonable")
require("util/primitive")

###*
@class Board
  Base class for embedded boards (Model)
@extends JSONable
###
module.exports = class Board extends JSONable
  null

  #--------------------------------------------------------------------------------
  # Public properties
  #

  ###*
  @property {string} id
    ID of this board class
  @readonly
  ###
  @property("id", get: -> @constructor.id)

  ###*
  @property {string} rubicVersion
    Compatible Rubic version class
  @readonly
  ###
  @property("rubicVersion", get: -> @constructor.rubicVersion)

  ###*
  @property {I18n} friendlyName
    Name of this board class
  @readonly
  ###
  @property("friendlyName", get: -> @constructor.friendlyName)

  ###*
  @property {I18n} author
    Author of this board class
  @readonly
  ###
  @property("author", get: -> @constructor.author)

  ###*
  @property {string} website
    Website URL of this board class
  @readonly
  ###
  @property("website", get: -> @constructor.website)

  ###*
  @property {string[]} images
    List of images of this board class
    (The first item is used as an icon)
  @readonly
  ###
  @property("images", get: -> @constructor.images)

  ###*
  @property {string[]} boardRevisions
    List of board revisions of this board class
  @readonly
  ###
  @property("boardRevisions", get: -> @constructor.boardRevisions)

  ###*
  @property {string} boardRevision
    board revision
  ###
  @property("boardRevision",
    get: -> @_boardRevision
    set: (v) -> @_modify("_boardRevision", v)
  )

  ###*
  @property {string} firmwareId
    ID of firmware
  @readonly
  ###
  @property("firmwareId",
    get: -> @_firmwareId
  )

  ###*
  @property {string} firmRevisionId
    ID of firmware revision
  @readonly
  ###
  @property("firmRevisionId",
    get: -> @_firmRevisionId
  )

  ###*
  @property {boolean} debuggable
    Debug support
  @readonly
  ###
  @property("debuggable",
    get: -> false
  )

  ###*
  @property {boolean} connected
  ###
  @property("connected", get: -> @_connected)

  #--------------------------------------------------------------------------------
  # Events
  #

  ###*
  @event change.board
    Board changed
  @param {Object} event
    Event object
  @param {Board} event.target
    Board instance
  ###
  @event("change.board")

  ###*
  @event connect.board
    Connected event target
  @param {Object} event
    Event object
  @param {Board} event.target
    Board instance
  ###
  @event("connect.board")

  ###*
  @event disconnect.board
    Disconnected
  @param {Object} event
    Event object
  @param {Board} event.target
    Board instance
  ###
  @event("disconnect.board")

  #--------------------------------------------------------------------------------
  # Public methods
  #

  ###*
  @method
    Load firmware instance
  @return {Promise}
    Promise object
  @return {Firmware} return.PromiseValue
    Firmware instance
  ###
  loadFirmware: ->
    return I18n.rejectPromise("Firmware_is_not_selected") unless @_firmwareId?
    return Promise.resolve(@_firmware) if @_firmware?
    return Promise.resolve(
    ).then(=>
      return @_boardCatalog if @_boardCatalog?
      return BoardCatalog.load(false)
    ).then((catalog) =>
      @_boardCatalog = catalog
      return (@_firmCatalog or= @_boardCatalog.getFirmCatalog(@constructor))
    ).then(=>
      f = @_firmCatalog?.getFirmware(@_firmwareId)
      return (@_firmware = f) if f?
      return I18n.rejectPromise("Firmware_not_cached")
    ) # return Promise.resolve().then()...

  ###*
  @method
    Set firmware instance
  @param {Firmware} firmware
    Firmware instance
  @return {undefined}
  ###
  setFirmware: (firmware) ->
    return if firmware == @_firmware
    @_firmware = firmware
    @_firmwareId = firmware?.id
    return

  ###*
  @method
    Load firmware revision instance
  @return {Promise}
    Promise object
  @return {FirmRevision} return.PromiseValue
    FirmRevision instance
  ###
  loadFirmRevision: ->
    return Promise.resolve(@_firmRevision) if @_firmRevision?
    return Promise.resolve(
    ).then(=>
      return @_boardCatalog if @_boardCatalog?
      return BoardCatalog.load(false)
    ).then((catalog) =>
      @_boardCatalog = catalog
      return (@_firmCatalog or= @_boardCatalog.getFirmCatalog(@constructor))
    ).then(=>
      r = @_firmCatalog?.getFirmRevision(@_firmRevisionId)
      return (@_firmRevision = r) if r?
      return I18n.rejectPromise("Firmware_revision_not_cached")
    ) # return Promise.resolve().then()...

  ###*
  @method
    Set firmware revision instance
  @param {FirmRevision} firmRevision
    FirmRevision instance
  @return {undefined}
  ###
  setFirmRevision: (firmRevision) ->
    return if firmRevision == @_firmRevision
    @_firmRevision = firmRevision
    @_firmRevisionId = firmRevision?.id
    return

  ###*
  @template
  @method
    Get list of pins
  @return {Object}
    Pin definition
  @return {Object} return.left
    Left side definition
  @return {Object} return.right
    Right side definition
  @return {string[]/I18n[]} return.aliases
    Name of alias groups
  ###
  getPinList: ->
    return {}

  ###*
  @template
  @method
    Get programmer
  @return {Programmer}
    Programmer instance
  ###
  getProgrammer: ->
    return null # No programmer

  ###*
  @template
  @method
    Enumerate boards
  @return {Promise}
    Promise object
  @return {Object[]} return.PromiseValue
    Array of board information {friendlyName: "name for UI", path: "path", details: "detail info"}
  ###
  enumerate: null # pure virtual

  ###*
  @template
  @method
    Connect to board
  @param {string} path
    Path of the board
  @return {Promise}
    Promise object
  @return {undefined} return.PromiseValue
  ###
  connect: null # pure virtual

  ###*
  @template
  @method
    Disconnect from board
  @return {Promise}
    Promise object
  @return {undefined} return.PromiseValue
  ###
  disconnect: null # pure virtual

  ###*
  @template
  @method
    Get board information
  @return {Promise}
    Promise object
  @return {Object} return.PromiseValue
    Board information
  @return {string} return.PromiseValue.path
    Path of device
  @return {string/undefined} return.PromiseValue.boardRevision
    board revision
  @return {string} return.PromiseValue.firmwareRevision
    Firmware revision
  @return {string/undefined} return.PromiseValue.serialNumber
    Serial number
  ###
  getBoardInfo: null # pure virtual

  ###*
  @template
  @method
    Get list of storages
  @return {Promise}
    Promise object
  @return {string[]} return.PromiseValue
  ###
  getStorages: null # pure virtual

  ###*
  @template
  @method
    Request pseudo filesystem
  @param {string} storage
    Name of storage
  @return {Promise}
    Promise object
  @return {AsyncFs} return.PromiseValue
    File system object
  ###
  requestFileSystem: null # pure virtual

  ###*
  @template
  @method
    Start sketch
  @param {string} target
    Target file name
  @param {function(boolean):undefined} onFinished
    Callback for finish with result
  @return {Promise}
    Promise object
  @return {BoardConsole} return.PromiseValue
    Console object
  ###
  startSketch: null # pure virtual

  ###*
  @template
  @method
    Stop sketch
  @return {Promise}
    Promise object
  ###
  stopSketch: null # pure virtual

  #--------------------------------------------------------------------------------
  # Protected methods
  #

  ###*
  @method constructor
    Constructor of Board class
  @param {Object} obj
    JSON object
  ###
  constructor: (obj = {}) ->
    super(obj)
    # TODO: Rubic version check
    @_boardRevision   = obj.boardRevision?.toString?()
    @_firmwareId      = obj.firmwareId?.toString?()
    @_firmRevisionId  = obj.firmRevisionId?.toString?()
    @_connected       = false
    @_modify = (key, value) =>
      if key?
        return if @[key] == value
        @[key] = value
      @_modified = true
      @dispatchEvent({type: "change"})
    return

  ###*
  @method
    Convert to JSON object
  @return {Object}
  ###
  toJSON: ->
    return super().extends({
      friendlyName    : @constructor.friendlyName
      rubicVersion    : @constructor.rubicVersion
      boardRevision   : @_boardRevision
      firmwareId      : @_firmwareId
      firmRevisionId  : @_firmRevisionId
    })

  ###*
  @protected
  @method
    Raise error on already connected
  @return {Promise}
    Promise object (rejection)
  ###
  errorConnected: ->
    return I18n.rejectPromise("Already_connected")

  ###*
  @protected
  @method
    Raise error on not connected
  @return {Promise}
    Promise object (rejection)
  ###
  errorNotConnected: ->
    return I18n.rejectPromise("Not_connected")

  ###*
  @protected
  @method
    Set connected state
  @param {boolean} state
    State of connection
  @return {undefined}
  ###
  setConnectState: (state) ->
    state = !!state
    return if state == @_connected
    @_connected = state
    @dispatchEvent({type: if @_connected then "connect" else "disconnect"})
    return

# Post dependencies
I18n = require("util/i18n")
BoardCatalog = require("firmware/boardcatalog")
