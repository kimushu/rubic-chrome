"use strict"
# Pre dependencies
# (none)

###*
@class FirmCatalog
  Firmware catalog
  (One FirmCatalog instance retains the firmware list of one board)
@extends JSONable
###
module.exports = class FirmCatalog
  null

  #--------------------------------------------------------------------------------
  # Public properties
  #

  ###*
  @property {number} lastFetched
    Timestamp of last fetched date (in milliseconds from epoch, UTC)
  @readonly
  ###
  @property("lastFetched", get: -> @_lastFetched)

  ###*
  @property {number} lastModified
    Timestamp of last modified date (in milliseconds from epoch, UTC)
  @readonly
  ###
  @property("lastModified", get: -> @_lastModified)

  ###*
  @property {string} boardId
    Board class ID for this catalog instance
  @readonly
  ###
  @property("boardId", get: -> @_boardClass?.id)

  ###*
  @property {Function} boardClass
    Board class for this catalog instance
  @readonly
  ###
  @property("boardClass", get: -> @_boardClass)

  #--------------------------------------------------------------------------------
  # Private variables / constants
  #

  #--------------------------------------------------------------------------------
  # Public methods
  #

  ###*
  @method
    Get ID list of firmwares
  @return {string[]}
    ID list of firmwares
  ###
  getFirmwareIDs: ->
    return (i.firmware.id for i in @_items)

  ###*
  @method
    Get firmware instance
  @param {string} firmwareId
    ID of firmware
  @return {Firmware}
    Firmware instance
  ###
  getFirmware: (firmwareId) ->
    for i in @_items
      return i.firmware if i.firmware.id == firmwareId
    return  # Not found

  ###*
  @method
    Get ID list of revisions
  @param {string} firmwareId
    Firmware ID
  @return {string[]}
    ID list of revisions
  ###
  getFirmRevisionIDs: (firmwareId) ->
    for i in @_items
      continue unless i.firmware.id == firmwareId
      return (r.id for r in i.revisions)
    return [] # Not found

  ###*
  @method
    Get firmware revision instance
  @param {string} firmRevisionId
    ID of firmware revision
  @return {FirmRevision}
    Firmware revision instance
  ###
  getFirmRevision: (firmRevisionId) ->
    for i in @_items
      for r in i.revisions
        return r if r.id == firmRevisionId
    return  # Not found

  ###*
  @method constructor
    Constructor of FirmCatalog class
  @param {Function} _boardClass
    Board class constructor
  @param {Object} obj
    JSON object
  ###
  constructor: (@_boardClass, obj = {}) ->
    @_lastFetched = parseInt(obj.lastFetched || 0)
    @_lastModified = parseInt(obj.lastModified || 0)
    @_items = ({
      firmware: Firmware.parseJSON(i.firmware)
      revisions: (FirmRevision.parseJSON(r) for r in (i.revisions or []))
    } for i in (obj.items or []))
    return

# Post dependencies
Firmware = require("./firmware")
FirmRevision = require("./firmrevision")
