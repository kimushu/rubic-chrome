if global.bootbox?.alert?
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

if global.bootbox?.confirm?
  global.bootbox.confirm_p = (arg) ->
    return new Promise((resolve, reject) ->
      opt = {}
      if typeof(arg) == "string"
        opt.message = arg
      else
        (opt[k] = v) for k, v of arg
      opt.callback = (result) ->
        return resolve() if result
        return reject(Error("Cancelled"))
      global.bootbox.confirm(opt)
    )

if global.bootbox?.prompt?
  global.bootbox.prompt_p = (arg) ->
    return new Promise((resolve, reject) ->
      opt = {}
      if typeof(arg) == "string"
        opt.title = arg
      else
        (opt[k] = v) for k, v of arg
      opt.callback = (result) ->
        return reject(Error("Cancelled")) unless result?
        return resolve(result)
      global.bootbox.prompt(opt)
    )

if global.bootbox?.dialog?
  global.bootbox.dialog_p = (arg) ->
    return new Promise((resolve, reject) ->
      opt = {}
      (opt[k] = v) for k, v of arg
      opt.onEscape = -> reject(Error("Cancelled"))
      opt.buttons = {}
      for name, btn of (arg.buttons or {})
        btn2 = {}
        (btn2[k2] = v2) for k2, v2 of btn
        btn2.callback = -> resolve(name)
        opt.buttons[name] = btn2
      global.bootbox.dialog(opt)
    )

module.exports = null
