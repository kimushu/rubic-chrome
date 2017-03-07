"use strict"

###*
Create promisified IPC caller (sender)

@method createCaller
@param {string} channel
  Channel name
@param {Object} ipc
  IPC sender object (ipcMain / ipcRenderer)
@return {function}
  Caller function
###
createCaller = (channel, ipc) ->
  replyId = "#{channel}-reply"
  callId = "#{channel}-call"
  caller = (args...) ->
    ++caller._called
    id = Math.random().toString(36).substring(2)
    ipc.send(callId, id, args)
    return new Promise((resolve, reject) ->
      caller._requests[id] = {resolve, reject}
    )
  caller._called = 0
  caller._requests = {}
  listener = (event, id, data) ->
    req = caller._requests[id]
    delete caller._requests[id]
    return unless req
    return req.reject(data.error) if data.error?
    return req.resolve(data.result)
  ipc.on(replyId, listener)
  caller.dispose = ->
    ipc.removeListener(replyId, listener)
  return caller

###*
Create promisified IPC callee (receiver)

@method createCallee
@param {string} channel
  Channel name
@param {Object} ipc
  IPC receiver object (ipcMain / ipcRenderer)
@param {function} callback
  Callback function with Promise result
@return {Object}
  Disposable object
###
createCallee = (channel, ipc, callback) ->
  replyId = "#{channel}-reply"
  callId = "#{channel}-call"
  callee = {_called: 0}
  listener = (event, id, args) ->
    Promise.resolve().then(->
      ++callee._called
      return callback(args...)
    ).then((result) ->
      event.sender.send(replyId, id, {result})
    ).catch((error = null) ->
      event.sender.send(replyId, id, {error})
    )
  ipc.on(callId, listener)
  callee.dispose = ->
    ipc.removeListener(callId, listener)
  return callee

module.exports = {createCaller, createCallee}
