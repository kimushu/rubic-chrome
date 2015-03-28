class MRubyBuilder extends Builder
  Builder.addBuilder(this)

  #----------------------------------------------------------------
  # Class attributes/methods

  @suffix = ["rb"]

  #----------------------------------------------------------------
  # Instance attributes/methods

  ###*
  Constructor
  @param {DirectoryEntry} dirEntry      Directory to store output files
  @param {FileEntry}      fileEntry     Source file
  @param {String}         opt.version   Prefered version @nullable
  ###
  constructor: (@dirEntry, @fileEntry, opt) ->
    @options = $.extend({version: "1.0.0"}, opt)

  ###*
  Build mruby source
  @param {Function} callback  Callback ({Boolean} result, {Number} length)
  ###
  build: (callback) ->
    FileUtil.readText(
      @fileEntry
      (result, readdata) =>
        return callback(false) unless result
        rb_name = "/#{@fileEntry.name}"
        mrb_name = "/out.mrb"
        module = {
          print: (data) ->
            console.log("mruby(stdout):#{data}")
          printErr: (data) ->
            console.log("mruby(stderr):#{data}")
          preRun: [->
            module.exports.FS.writeFile(rb_name, readdata, {encoding: "utf8"})
          ]
          "arguments": ["-o#{mrb_name}", rb_name].concat(@options.flags or [])
        }
        Lib.mrbc(module)
        output = module.exports.FS.readFile(mrb_name)
        FileUtil.writeArrayBuf(
          [@dirEntry, @fileEntry.name.replace(/\.[^.]+$/, "") + ".mrb"]
          output
          (result) ->
            return callback(false) unless result
            callback(true, output.byteLength)
        ) # FileUtil.writeArrayBuf
    ) # FileUtil.readText

