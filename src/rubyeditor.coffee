class RubyEditor extends Editor
  Editor._extendedBy(this)

  @suffix: ["rb"]

  constructor: (fileEntry) ->
    super(fileEntry, "ace/mode/ruby")

