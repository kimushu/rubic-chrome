class Builder
  @_subclasses: []
  @_extendedBy: (subclass) -> @_subclasses.push(subclass)

  @createBuilder: (dirEntry, fileEntry) ->
    suffix = (fileEntry.name.match(/\.([^.]+)$/)[1] or "").toLowerCase()
    console.log("searching suffix: " + suffix)
    for c in Builder._subclasses
      return new c(dirEntry, fileEntry) if c.suffix.indexOf(suffix) >= 0
