class Builder
  #----------------------------------------------------------------
  # Class attributes/methods

  ###*
  Create new builder instance
  @param {DirectoryEntry} dirEntry    Directory to store output files
  @param {FileEntry}      fileEntry   Source file
  @param {Object}         options     Options for builder @nullable
  @param {String}         className   Builder class name @nullable
  ###
  @createBuilder: (dirEntry, fileEntry, options, className) ->
    if className
      found = (b for b in @_builders when b.name == className)
    else
      suffix = (fileEntry.name.match(/\.([^.]+)$/)[1] or "").toLowerCase()
      found = (b for b in @_builders when b.suffix.indexOf(suffix) >= 0)

    return new found[0](dirEntry, fileEntry, options) if found.length > 0

    if className
      App.lastError = "Builder '#{className}' not found"
    else
      App.lastError = "No builder found for '*.#{suffix}' file"
    null

  ###*
  @protected
  Register builder class
  ###
  @addBuilder: (builder) -> @_builders.push(builder)

  ###*
  @private
  List of builder classes
  ###
  @_builders: []

