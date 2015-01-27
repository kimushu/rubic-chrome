class MRubyBuilder extends Builder
  Builder._extendedBy(this)
  @suffix = ["rb"]

  constructor: (@dirEntry, @fileEntry, @flags) -> null

  build: (successCallback, errorCallback) -> do (self = this) ->
    FileUtil.readEntryText(
      self.fileEntry,
      null,
      ((rb_contents) ->
        console.log({"compiling mruby...": self.fileEntry})
        rb_name = "/#{self.fileEntry.name}"
        mrb_name = "/out.mrb"
        module = {
          print: (data) ->
            console.log({"stdout": data})
          printErr: (data) ->
            console.log({"stderr": data})
          read: (filename, binary) ->
            console.log("Module.read: " + filename)
          preRun: [->
            module.exports.FS.writeFile(rb_name, rb_contents, {encoding: "binary"})
          ]
          "arguments": ["-o#{mrb_name}", rb_name].concat(self.flags || [])
        }
        Lib.mrbc(module)
        console.log({result: module.exports.FS.readFile(mrb_name)})
        successCallback()
      ),
      errorCallback
    )

