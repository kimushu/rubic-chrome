###*
@class Rubic.Builder
  Builder class
###
class Rubic.Builder
  DEBUG = Rubic.DEBUG or 0

  ###*
  @protected
  @static
  @method
    Register builder class
  @param {Function} builderClass
    Constructor of subclass
  @return {void}
  ###
  @addBuilder: (builderClass) ->
    (@_builders or= {})[builderClass.name] = builderClass
    return

  ###*
  @static
  @inheritable
  @cfg {string[]} SUFFIXES
    List of supported suffixes
  @readonly
  ###
  @SUFFIXES: []

  ###*
  @protected
  @cfg {Object} DEFAULT_OPTIONS
    Default options
  @readonly
  ###
  DEFAULT_OPTIONS: {}

  ###*
  @static
  @method
    Guess builder class from filename
  @param {string} name
    File name
  @return {Function}
    Constructor of builder (return void if no suitable class)
  ###
  @guessBuilderClass: (name) ->
    suffix = name.match(/\.([^.]+)$/)?[1]?.toLowerCase()
    return unless suffix
    for name, builderClass of @_builders
      return builderClass if builderClass.SUFFIXES.includes(suffix)
    return

  ###*
  @protected
  @method constructor
    Constructor of Builder classes
  @param {Rubic.Sketch} _sketch
    The instance of sketch
  @param {string} _sourcePath
    Relative path of source file
  @param {Object} [_options]
    Build options
  ###
  constructor: (@_sketch, @_sourcePath, @_options) ->
    @_options or= @DEFAULT_OPTIONS
    return

  # #----------------------------------------------------------------
  # # >>>> OLD contents >>>>

  # #----------------------------------------------------------------
  # # Class attributes/methods

  # ###*
  # Create new builder instance
  # @param {DirectoryEntry} dirEntry    Directory to store output files
  # @param {FileEntry}      fileEntry   Source file
  # @param {Object}         options     Options for builder @nullable
  # @param {String}         className   Builder class name @nullable
  # ###
  # @createBuilder: (dirEntry, fileEntry, options, className) ->
  #   if className
  #     found = (b for b in @_builders when b.name == className)
  #   else
  #     suffix = (fileEntry.name.match(/\.([^.]+)$/)[1] or "").toLowerCase()
  #     found = (b for b in @_builders when b.suffix.indexOf(suffix) >= 0)

  #   return new found[0](dirEntry, fileEntry, options) if found.length > 0

  #   if className
  #     App.lastError = "Builder '#{className}' not found"
  #   else
  #     App.lastError = "No builder found for '*.#{suffix}' file"
  #   null

  # ###*
  # @protected
  # Register builder class
  # ###
  # @addBuilder: (builder) -> @_builders.push(builder)

  # ###*
  # @private
  # List of builder classes
  # ###
  # @_builders: []

  # ###*
  # @method
  # Get builder class from its name
  # ###
  # @getBuilder: (name) ->
  #   return b for b in @_builders when b.name == name
  #   null

