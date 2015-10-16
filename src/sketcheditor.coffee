###*
@class
  Editor for sketch configuration (View)
@extends Editor
###
class SketchEditor extends Editor
  DEBUG = if DEBUG? then DEBUG else 0
  Editor.addEditor(this)

