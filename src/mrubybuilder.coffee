class MRubyBuilder extends Builder
  Builder.addBuilder(this)
  DEBUG_LIB = false

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
    @options = $.extend({version: "1.0.0", flags: ["-g"]}, opt)

  ###*
  Build mruby source
  @param {Function} callback  Callback ({Boolean} result, {Number} length)
  ###
  build: (callback) ->
    FileUtil.readText(
      @fileEntry
      (result, readdata) =>
        return callback?(false) unless result
        src_path = "/#{@fileEntry.name}"
        src_data = readdata
        dest_path = "#{src_path.replace(/\.[^.]+$/, "")}.mrb"
        dest_data = null
        runner = new EmscriptenRunner("mrbc")
        runner.addFile(src_path, src_data, {encoding: "utf8"})
        runner.execute("-o#{dest_path}", @options.flags or [], src_path)
        if runner.exitstatus != 0
          App.lastError = "Build failed (exitstatus=#{runner.exitstatus})"
          return callback?(false)

        dest_data = runner.getFileAsArrayBuffer(dest_path)
        unless dest_data
          App.lastError = "Build failed"
          return callback?(false)

        FileUtil.writeArrayBuf(
          [@dirEntry, dest_path.slice(1)]
          dest_data
          (result) ->
            return callback?(false) unless result
            callback?(true, dest_data.byteLength)
        ) # FileUtil.writeArrayBuf
    ) # FileUtil.readText

