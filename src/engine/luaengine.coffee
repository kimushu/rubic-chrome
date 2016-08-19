"use strict"
# Pre dependencies
Engine = require("engine/engine")
require("util/primitive")

###*
@class LuaEngine
  Script execution engine for Lua (Model)
@extends Engine
###
module.exports = class LuaEngine extends Engine
  Engine.jsonable(this)

  #--------------------------------------------------------------------------------
  # Public properties
  #

  ###*
  @inheritdoc Engine#friendlyName
  ###
  @property("friendlyName", get: -> "Lua")

  ###*
  @inheritdoc Engine#languageName
  ###
  @property("languageName", get: -> "Lua")

  ###*
  @inheritdoc Engine#fileTypes
  ###
  @property("fileTypes", get: -> [
    {
      suffix: "lua"
      name: {en: "Lua script", ja: "Lua スクリプト"}
    }
  ])

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

# Post dependencies
# (none)
