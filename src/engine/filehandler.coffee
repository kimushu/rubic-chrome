"use strict"
# Pre dependencies
require("util/primitive")

###*
@class
  File handler class
###
module.exports = class FileHandler
  null

  ###*
  @property {string/null} suffix
    Suffix
  @readonly
  ###
  @property("suffix", get: -> @_suffix)

  ###*
  @property {RegExp} pattern
    Pattern
  @readonly
  ###
  @property("pattern", get: -> @_pattern)

  ###*
  @property {I18n} description
    Description
  @readonly
  ###
  @property("description", get: -> @_description)

  ###*
  @property {Engine} engine
    Associated engine
  @readonly
  ###
  @property("engine", get: -> @_engine)

  ###*
  @property {I18n} template
    Template string
  @readonly
  ###
  @property("template", get: -> @_template)

  ###*
  @property {boolean} hasCompilerOptions
    Has compiler options
  @readonly
  ###
  @property("hasCompilerOptions", get: -> @_hasCompilerOptions)

  ###*
  @method
    Test file support
  @param {string} path
    File path (can include directories)
  @return {boolean}
    Test result
  ###
  supports: (path) ->
    name = path.split("/").pop()
    return !!name.match(@_pattern)

  ###*
  @method constructor
    Constructor of FileHandler class
  @param {Engine} _engine
    Engine associated to this file type
  @param {string/RegExp} suffix_or_pattern
    Suffix(string) or name pattern(RegExp)
  @param {Object} [options]
    Various options
  @param {I18n} [options.description=null]
    Description of this file
  @param {I18n} [options.template=null]
    Template string
  @param {boolean} [options.hasCompilerOptions=false]
    Has compiler options
  ###
  constructor: (@_engine, suffix_or_pattern, options = {}) ->
    if typeof(suffix_or_pattern) == "string"
      @_suffix = suffix_or_pattern
      @_pattern = new RegExp("\\.#{@_suffix}$", "i")
    else if suffix_or_pattern instanceof RegExp
      @_suffix = null
      @_pattern = suffix_or_pattern
    @_description = options.description
    @_template = options.template
    @_hasCompilerOptions = !!options.hasCompilerOptions
    return

# Post dependencies
# (none)
