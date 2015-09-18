###*
@class
Hardware configuration class
###
class HardwareConfig
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
  Constructor of HardwareConfig
  ###
  constructor: (c_uuid, v_uuid, callback) ->
    FileUtil.requestPersistentFileSystem(
      (fs) ->
        FileUtil.readJSON([fs.root, "catalog.json"], (result, readdata) =>
          return callback(null) unless result
          for item in readdata
            return callback(@_load(item, v_uuid))
          console.log("error: UUID (#{uuid}) is not found in local catalog")
          return callback(null)
        )
      -> callback(null)
    )

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

