###*
@class
Editor for ruby/mruby source
###
class RubyEditor extends Editor
  Editor.addEditor(this)
  @suffix: ["rb"]
  @editable: true

  ###*
  Constructor
  ###
  constructor: (fileEntry) ->
    super(fileEntry, "ace/mode/ruby")

