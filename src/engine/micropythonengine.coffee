"use strict"
# Pre dependencies
Engine = require("engine/engine")
require("util/primitive")

###*
@class MicroPythonEngine
  Script execution engine for MicroPython (Model)
@extends Engine
###
module.exports = class MicroPythonEngine extends Engine
  Engine.jsonable(this)

  #--------------------------------------------------------------------------------
  # Public properties
  #

  ###*
  @inheritdoc Engine#friendlyName
  ###
  @classProperty("friendlyName", get: -> "MicroPython")

  ###*
  @inheritdoc Engine#languageName
  ###
  @classProperty("languageName", get: -> "Python3")

  ###*
  @inheritdoc Engine#fileTypes
  ###
  @classProperty("fileTypes", get: -> [
    {
      suffix: "py"
      name: {en: "Python script", ja: "Python スクリプト"}
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
