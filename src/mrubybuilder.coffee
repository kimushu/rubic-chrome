class MRubyBuilder extends Builder
  Builder.addBuilder(this)
  HardwareCatalog.addFeature(this)
  DEBUG_LIB = false

  #----------------------------------------------------------------
  # Class attributes/methods

  @FEATURE_COLOR: "#c7311d"

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
        return callback?(false) unless result
        rb_name = "/#{@fileEntry.name}"
        mrb_name = "/out.mrb"
        log = [""]
        module = {
          print: (data) ->
            console.log("mruby(stdout):#{data}") if DEBUG_LIB
          printErr: (data) ->
            console.log("mruby(stderr):#{data}") if DEBUG_LIB
            log.push(data.substring(1)) if data.lastIndexOf("/", 0) == 0
          preRun: [->
            module.exports.FS.writeFile(rb_name, readdata, {encoding: "utf8"})
          ]
          "arguments": ["-o#{mrb_name}", rb_name].concat(@options.flags or [])
        }
        Lib.mrbc(module)
        try
          output = module.exports.FS.readFile(mrb_name)
        catch
          log.push("")
          App.lastError = log.join("<br/>")
          return callback?(false)
        FileUtil.writeArrayBuf(
          [@dirEntry, @fileEntry.name.replace(/\.[^.]+$/, "") + ".mrb"]
          output
          (result) ->
            return callback?(false) unless result
            callback?(true, output.byteLength)
        ) # FileUtil.writeArrayBuf
    ) # FileUtil.readText

