"use strict"
#--------------------------------------------------------------------------------
# Promise-based wrapper for Bootbox.js
#

global.bootbox.CancellationError or= class CancellationError
  constructor: (message) ->
    return new CancellationError(message) unless this instanceof CancellationError
    message = "operation cancelled" unless typeof(message) == "string"
    Object.defineProperty(this, "message", value: message)
    Object.defineProperty(this, "name", value: "CancellationError")
    if Error.captureStackTrace?
      Error.captureStackTrace(this, @constructor)
    else
      Error.call(this)
    return

if global.bootbox.alert?
  global.bootbox.alert_p = (arg) ->
    return new Promise((resolve) ->
      opt = {}
      if typeof(arg) == "string"
        opt.message = arg
      else
        (opt[k] = v) for k, v of arg
      opt.callback = resolve
      global.bootbox.alert(opt)
    )

if global.bootbox.confirm?
  global.bootbox.confirm_p = (arg) ->
    return new Promise((resolve, reject) ->
      opt = {}
      if typeof(arg) == "string"
        opt.message = arg
      else
        (opt[k] = v) for k, v of arg
      opt.callback = (result) ->
        return resolve() if result
        return reject(new global.bootbox.CancellationError())
      global.bootbox.confirm(opt)
    )

if global.bootbox.prompt?
  global.bootbox.prompt_p = (arg) ->
    return new Promise((resolve, reject) ->
      opt = {}
      if typeof(arg) == "string"
        opt.title = arg
      else
        (opt[k] = v) for k, v of arg
      opt.callback = (result) ->
        return resolve(result) if result
        return reject(new global.bootbox.CancellationError())
      global.bootbox.prompt(opt)
    )

if global.bootbox.dialog?
  global.bootbox.dialog_p = (arg) ->
    return new Promise((resolve, reject) ->
      opt = {}
      (opt[k] = v) for k, v of arg
      opt.onEscape = -> reject(new global.bootbox.CancellationError())
      opt.buttons = {}
      for name, btn of (arg.buttons or {})
        btn2 = {}
        (btn2[k2] = v2) for k2, v2 of btn
        do (name) -> btn2.callback = -> resolve(name)
        opt.buttons[name] = btn2
      global.bootbox.dialog(opt)
    )

