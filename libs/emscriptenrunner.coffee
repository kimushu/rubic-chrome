Module = {
  ENVIRONMENT: "WEB"
  noInitialRun: true
  preRun: []
  postRun: []
  thisProgram: @constructor.name
}

preRunPromise = new Promise((resolve) -> Module.preRun.push(resolve))
stdout = []
stderr = []
calledMain

@exitstatus = undefined

@onStdout = undefined

Module.stdout = (charCode) ->
  return if @onStdout?(charCode)
  stdout.push(charCode)

@onStderr = undefined

Module.stderr = (charCode) ->
  return if @onStderr?(charCode)
  stderr.push(charCode)

@setup = ->
  return preRunPromise.then(-> return)

@run = (args...) ->
  return Promise.reject(Error("Already run")) if calledMain
  return new Promise((resolve) ->
    Module.callMain(args)
    resolve(@exitstatus = EXITSTATUS)
  )

@writeFile = (path, data, options) ->
  return new Promise((resolve) ->
    FS.writeFile(path, data, options)
    resolve()
  )

@readFile = (path, options) ->
  return new Promise((resolve) ->
    data = FS.readFile(path, options)
    resolve(data)
  )

@readStdout = (length) ->
  length = stdout.length unless length?
  length = Math.min(length, stdout.length)
  return stdout.splice(0, length)

@readStderr = (length) ->
  length = stderr.length unless length?
  length = Math.min(length, stderr.length)
  return stderr.splice(0, length)

