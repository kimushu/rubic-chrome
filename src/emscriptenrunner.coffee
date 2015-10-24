###*
@class Rubic.EmscriptenRunner
  Runner class for emscripten libraries
###
class Rubic.EmscriptenRunner
  ###*
  @method constructor
    Constructor of EmscriptenRunner
  @param {string} _lib
    Library name
  ###
  constructor: (@_lib) ->
    @_module = {
      print: (text) ->
        app.log(text)
      printErr: (text) ->
        app.log(text)
      stdout: (code) =>
        @_stdoutChar(code)
      stderr: (code) =>
        @_stderrChar(code)
      preRun: [=> @_preRun()]
      exit: [(value) => @_exitstatus = value]
      thisProgram: "#{@_lib}"
    }
    @_files = []
    @_printCommandLine = true
    @_stdout = (text) -> app.main.stdout(text)
    @_stderr = (text) -> app.main.stderr(text)
    @_exitstatus = null
    return

  ###*
  @property {boolean}
    Enables print command line
  ###
  @property("printCommandLine",
    get: -> @_printCommandLine,
    set: (value) -> @_printCommandLine = !!value
  )

  ###*
  @property {function(string):void}
    Handler of stdout
  ###
  @property("stdout",
    get: -> @_stdout,
    set: (value) -> @_stdout = value
  )

  ###*
  @property {function(string):void}
    Handler of stderr
  ###
  @property("stderr",
    get: -> @_stderr,
    set: (value) -> @_stderr = value
  )

  ###*
  @property {number}
    Exit status code
  ###
  @property("exitstatus", get: -> @_exitstatus)

  ###*
  @private
  @method
    Print one character to stdout
  @param {number} code
    ASCII code
  @return {void}
  ###
  _stdoutChar: (code) ->
    @_outputChar(1, code)
    return

  ###*
  @private
  @method
    Print one character to stderr
  @param {number} code
    ASCII code
  @return {void}
  ###
  _stderrChar: (code) ->
    @_outputChar(2, code)
    return

  ###*
  @private
  @method
    Print one character to stderr
  @param {number} fd
    FD number (1 for stdout, 2 for stderr)
  @param {number} code
    ASCII code
  @return {void}
  ###
  _outputChar: (fd, code) ->
    if @_outputFd != fd and @_outputBuf
      switch(@_outputFd)
        when 1 then @_stdout(@_outputBuf)
        when 2 then @_stderr(@_outputBuf)
      @_outputBuf = null
    return unless fd
    @_outputFd = fd
    @_outputBuf or= ""
    @_outputBuf += String.fromCharCode(code)
    @_outputChar(0) if code == 0x0a
    return

  ###*
  @method
    Add input file
  @param {string} path
    Path of file
  @param {ArrayBuffer/string} data
    Contents of file
  @param {Object} options
    Options
  @return {void}
  ###
  addFile: (path, data, options) ->
    @_files.push({path: path, data: data, options: options})
    return

  ###*
  @private
  @method
    Function called at preRun
  @return {void}
  ###
  _preRun: ->
    for f in @_files
      @_module.exports.FS.writeFile(f.path, f.data, f.options)
    return

  ###*
  @method
    Execute
  @param {string[]} options
  @return {void}
  ###
  execute: (args...) ->
    @_module.arguments = Array.prototype.concat.apply([], args)
    @_stdout("(emscripten) #{@_lib} #{args.join(" ")}\n") if @_printCommandLine
    Rubic.Lib[@_lib](@_module)
    @_outputChar(0)
    return

  ###*
  @method
    Get contents of file
  @param {string} path
    Path of file
  @return {ArrayBuffer/null}
    Contents of file
  ###
  getFileAsArrayBuffer: (path) ->
    try
      return @_module.exports.FS.readFile(path)
    catch
      return null

