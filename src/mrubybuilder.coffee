###*
@class Rubic.MrubyBuilder
  Builder for mruby
@extends Rubic.Builder
###
class Rubic.MrubyBuilder extends Rubic.Builder
  DEBUG = Rubic.DEBUG or 0
  Rubic.Builder.addBuilder(this)

  ###*
  @static
  @cfg {string[]} SUFFIXES
    List of supported suffixes
  @readonly
  ###
  @SUFFIXES: ["rb"]

  ###*
  @method
    Execute build
  ###
  execute: (callback) ->
    esmodule = null
    src_path = "/#{@_sourcePath}"
    src_data = null
    dest_path = "#{src_path.replace(/\.[^.]+$/, "")}.mrb"
    dest_data = null
    new Function.Sequence(
      (seq) =>
        Rubic.FileUtil.readText(
          [@_sketch.dirEntry, src_path.slice(1)]
          (result, readdata) ->
            return seq.abort() unless result
            src_data = readdata
            return seq.next()
        )
      (seq) =>
        runner = new Rubic.EmscriptenRunner("mrbc")
        runner.addFile(src_path, src_data, {encoding: "utf8"})
        runner.execute("-o#{dest_path}", src_path, @_options.flags or [])
        if runner.exitstatus != 0
          app.log({info: "mrbc failed (#{runner.exitstatus})"})
          return seq.abort()
        dest_data = runner.getFileAsArrayBuffer(dest_path)
        return seq.abort() unless dest_data
        return seq.next()
      (seq) =>
        Rubic.FileUtil.writeArrayBuf(
          [@_sketch.dirEntry, dest_path.slice(1)]
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

