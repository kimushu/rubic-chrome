# Pre dependencies
Engine = require("./engine")

###*
@class LuaEngine
  Script execution engine for Lua (Model)
@extends Engine
###
class LuaEngine extends Engine
  Engine.jsonable(this)

  #--------------------------------------------------------------------------------
  # Public properties
  #

  ###*
  @inheritdoc Engine#coreName
  ###
  @classProperty("coreName", get: -> "Lua")

  ###*
  @inheritdoc Engine#langName
  ###
  @classProperty("langName", get: -> "Lua")

  ###*
  @inheritdoc Engine#suffixes
  ###
  @classProperty("suffixes", get: -> ["lua"])

  #--------------------------------------------------------------------------------
  # Public methods
  #

  ###*
  @inheritdoc Engine#setup
  ###
  setup: (sketch, item) ->
    item.transfered = true
    return Promise.resolve()

  ###*
  @inheritdoc Engine#build
  ###
  build: (sketch, item) ->
    return Promise.resolve()

module.exports = LuaEngine

# Post dependencies
# (none)
