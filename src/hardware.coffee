###*
@class Rubic.Hardware
  Combination of board and firmware (Model)
###
class Rubic.Hardware
  DEBUG = Rubic.DEBUG or 0

  ###*
  @property {string}
    Name of this hardware
  @readonly
  ###
  name: null

  ###*
  @property {Function}
    Constructor of board class
  @readonly
  ###
  boardClass: null

  ###*
  @property {string}
    UUID of this hardware
  @readonly
  ###
  hwUuid: null

  ###*
  @property {string}
    Name of selected version
  @readonly
  ###
  verName: null

  ###*
  @property {string}
    UUID of selected version
  @readonly
  ###
  verUuid: null

  ###*
  @property {string}
    Supported Rubic version
  @readonly
  ###
  rubicVersion: null

  ###*
  @property {Object} asset
    Asset information
  @property {string} asset.source
    Source URL of asset
  @property {string} asset.cache
    Cache URL of asset
  @readonly
  ###
  asset: null

  ###*
  @static
  @method
    Load hardware configuration from JSON object
  @param {Object} spec
    JSON object
  @param {string} spec.cuuid
    UUID of configuration
  @param {string} spec.vuuid
    UUID of version
  @param {function(result,HardwareConfig)}  callback
    Callback function with result and generated instance
  @return {void}
  ###
  @load: (spec, callback) ->
    unless spec.cuuid? and spec.vuuid?
      callback(false, null)
      return
    cat = null
    cfg = null
    new Function.Sequence(
      (seq) ->
        HardwareCatalog.load((result, catalog) ->
          return seq.abort() unless result
          cat = catalog
          return seq.next()
        )
      (seq) ->
        def = cat.getItem(spec.cuuid, spec.vuuid)
        unless def
          return seq.abort()
        cfg = new HardwareConfig(def)
        return seq.next()
    ).final(
      (seq) ->
        return callback(false, null) unless seq.finished
        return callback(true, cfg)
    ).start()
    return

  ###*
  @private
  @method constructor
    Constructor
  @param {Object} def
    Definition of hardware configuration
  ###
  constructor: (def) ->
    # TODO
    @name = def.name
    @boardClass = Board.getBoard(def.board_class)
    @hwUuid = def.hw_uuid
    @verName = def.ver_name
    @verUuid = def.ver_uuid
    return

  #----------------------------------------------------------------
  # >>>> OLD contents >>>>

  #----------------------------------------------------------------
  # Class attributes/methods

  ###*
  @static
  Load a new hardware configuration
  ###
  @load: (c_uuid, v_uuid, callback) ->
    new HardwareConfig(c_uuid, v_uuid, callback)

  #----------------------------------------------------------------
  # Instance attributes/methods

  ###*
  @private
  @method constructor
    Constructor of HardwareConfig
  ###
  #constructor: (c_uuid, v_uuid, callback) ->

  ###*
  @private
  Load hardware configuration
  ###
  _load: (@_item, v_uuid) ->
    @name = @_item.name
    @board = @_item.board_class
    @version = null
    ver = (v for v in @_item.versions when v.uuid == v_uuid)
    return null if ver.length == 0
    @version = ver[0]

  ###*
  @static
  @method
    Load hardware configuration
  @param {Object} cfg
    Selection information
  @param {string} cfg.c_uuid
    UUID of configuration
  @param {string} cfg.v_uuid
    UUID of version
  @param {function(boolean,HardwareConfig)} callback
    Callback with result and generated instance
  @return {void}
  ###
  @load: (cfg, callback) ->
    unless cfg.c_uuid and cfg.v_uuid
      callback(false, null)
      return
    HardwareCatalog.loadLocalCatalog((result, catalog) =>
      return callback(false, null) unless result
      c = catalog[cfg.c_uuid]
      unless c
        # catalog has no entry for c_uuid
        return callback(false, null)
      v = c.versions[cfg.v_uuid]
      unless v
        # catalog has no entry for c_uuid
        return callback(false, null)

      return callback(true, @constructor(c, v))
    )
    return

