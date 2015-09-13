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
    requester = (sc, ec) ->
      navigator.webkitPersistentStorage.queryUsageAndQuota(
        ((used, granted) ->
          window.webkitRequestFileSystem(
            window.PERSISTENT,
            granted,
            (fs) -> sc(fs.root),
            ec
          ) # webkitRequestFileSystem
        ),
        ec
      ) # queryUsageAndQuota
    requester((root) =>
      root.getFile(
        "catalog.json",
        {},
        ((entry) =>
          FileUtil.readText(entry, (result, readdata) =>
            return console.log("readText failed") unless result
            items = JSON.parse(readdata)
            for item in items
              continue unless item.uuid == c_uuid
              for ver in items.versions
                return callback(@_load(item, ver)) if ver.uuid == v_uuid
            console.log("error: UUID (#{uuid}) is not found in local catalog")
            return callback(null)
          ) # readText
        ),
        (-> console.log("getFile() failed"))
      ) # getFile
    ) # requester
    null

  ###*
  @private
  Load hardware configuration
  ###
  _load: (@_config, @_version) ->
    @name = @_config.name
    @board = @_config.board_class

