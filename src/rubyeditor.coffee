class RubyEditor extends Editor
  @suffix: ["rb"]

  _session: null

  constructor: (@_document)->
    @_session = ace.EditSession(@_document, 'ace/mode/ruby')

  activate: () ->
    

Editor.list.push RubyEditor
