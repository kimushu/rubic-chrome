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
  @property("friendlyName", get: -> "MicroPython")

  ###*
  @inheritdoc Engine#languageName
  ###
  @property("languageName", get: -> "Python3")

  ###*
  @inheritdoc Engine#fileHandlers
  ###
  @property("fileHandlers", get: -> @_fileHandlers or= [
    new FileHandler(this, "py",
      description: new I18n(
        en: "Python script"
        ja: "Python スクリプト"
      )
      template: new I18n("#!micropython\n")
    )
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
