###*
@class Rubic.MrubyBuilder
  Builder for mruby
@extends Rubic.Builder
###
class Rubic.MrubyBuilder extends Rubic.Builder
  DEBUG = Rubic.DEBUG or 0
  Rubic.Builder.addBuilder(this)

  ###*
  @method constructor
    Constructor of MrubyBuilder
  @param {Rubic.Sketch} _sketch
    The instance of sketch
  @param {string} _sourcePath
    Relative path of source file
  @param {Object} [_options]
    Build options
  ###
  constructor: (@_sketch, @_sourcePath, @_options) ->
    @_options or= {}
    return

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
          (result) ->
            return seq.next(result)
        )
    ).final(
      (seq) =>
        return
    ).start()
    return

  #----------------------------------------------------------------
  # >>>> OLD contents >>>>

  # HardwareCatalog.addFeature(this)
  # DEBUG_LIB = false

  # #----------------------------------------------------------------
  # # Class attributes/methods

  # @FEATURE_COLOR: "#c7311d"

  # @suffix = ["rb"]

  # #----------------------------------------------------------------
  # # Instance attributes/methods

  # ###*
  # Constructor
  # @param {DirectoryEntry} dirEntry      Directory to store output files
  # @param {FileEntry}      fileEntry     Source file
  # @param {String}         opt.version   Prefered version @nullable
  # ###
  # constructor: (@dirEntry, @fileEntry, opt) ->
  #   @options = $.extend({version: "1.0.0"}, opt)

  # ###*
  # Build mruby source
  # @param {Function} callback  Callback ({Boolean} result, {Number} length)
  # ###
  # build: (callback) ->
  #   FileUtil.readText(
  #     @fileEntry
  #     (result, readdata) =>
  #       return callback?(false) unless result
  #       rb_name = "/#{@fileEntry.name}"
  #       mrb_name = "/out.mrb"
  #       log = [""]
  #       module = {
  #         print: (data) ->
  #           console.log("mruby(stdout):#{data}") if DEBUG_LIB
  #         printErr: (data) ->
  #           console.log("mruby(stderr):#{data}") if DEBUG_LIB
  #           log.push(data.substring(1)) if data.lastIndexOf("/", 0) == 0
  #         preRun: [->
  #           module.exports.FS.writeFile(rb_name, readdata, {encoding: "utf8"})
  #         ]
  #         "arguments": ["-o#{mrb_name}", rb_name].concat(@options.flags or [])
  #       }
  #       Lib.mrbc(module)
  #       try
  #         output = module.exports.FS.readFile(mrb_name)
  #       catch
  #         log.push("")
  #         App.lastError = log.join("<br/>")
  #         return callback?(false)
  #       FileUtil.writeArrayBuf(
  #         [@dirEntry, @fileEntry.name.replace(/\.[^.]+$/, "") + ".mrb"]
  #         output
  #         (result) ->
  #           return callback?(false) unless result
  #           callback?(true, output.byteLength)
  #       ) # FileUtil.writeArrayBuf
  #   ) # FileUtil.readText

