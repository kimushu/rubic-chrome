###*
@class Rubic.CoffeeScriptBuilder
  Builder for CoffeeScript
@extends Rubic.Builder
###
class Rubic.CoffeeScriptBuilder extends Rubic.Builder
  DEBUG = Rubic.DEBUG or 0
  Rubic.Builder.addBuilder(this)

  ###*
  @static
  @cfg {string[]} SUFFIXES
    List of supported suffixes
  @readonly
  ###
  @SUFFIXES: ["coffee"]

  ###*
  @protected
  @cfg {Object} DEFAULT_OPTIONS
    Default options
  @readonly
  ###
  DEFAULT_OPTIONS: {header: true}

  ###*
  @method
    Execute build
  ###
  execute: (callback) ->
    src_path = "#{@_sourcePath}"
    src_data = null
    dest_path = "#{src_path.replace(/\.[^.]+$/, "")}.js"
    dest_data = null
    new Function.Sequence(
      (seq) =>
        Rubic.FileUtil.readText(
          [@_sketch.dirEntry, src_path]
          (result, readdata) ->
            return seq.abort() unless result
            src_data = readdata
            return seq.next()
        )
      (seq) =>
        try
          dest_data = app.background.CoffeeScript.compile(src_data, @_options)
        catch
          return seq.abort()
        return seq.next()
      (seq) =>
        Rubic.FileUtil.writeText(
          [@_sketch.dirEntry, dest_path]
          dest_data
          (result) ->
            return seq.next(result)
        )
    ).final(
      (seq) =>
        callback(seq.finished)
        return
    ).start()
    return

