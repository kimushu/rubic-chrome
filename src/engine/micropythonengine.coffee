"use strict"
# Pre dependencies
Engine = require("engine/engine")
require("util/primitive")

###*
@class MicroPythonEngine
  Script execution engine for MicroPython (Model)
@extends Engine
###
class MicroPythonEngine extends Engine
  Engine.jsonable(this)

  #--------------------------------------------------------------------------------
  # Public properties
  #

  ###*
  @inheritdoc Engine#coreName
  ###
  @classProperty("coreName", get: -> "MicroPython")

  ###*
  @inheritdoc Engine#langName
  ###
  @classProperty("langName", get: -> "Python 3")

  ###*
  @inheritdoc Engine#suffixes
  ###
  @classProperty("suffixes", get: -> ["py"])

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

module.exports = MicroPythonEngine

# Post dependencies
# (none)
