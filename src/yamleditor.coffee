###*
@class
Editor for YAML text
###
class YamlEditor extends Editor
  Editor.addEditor(this)
  @suffix: ["yml", "yaml"]
  @editable: true

  ###*
  Constructor
  ###
  constructor: (fileEntry) ->
    super(fileEntry, "ace/mode/yaml")

