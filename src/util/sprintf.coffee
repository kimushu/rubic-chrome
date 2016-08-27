"use strict"
RE = /%([#0 +-]*)(\*|\d*)((?:\.\d+)?)([diuoxXeEfFgGcs%])/g
RP = (values, match, flags, width, prec, type) ->
  for c in flags.split("")
    switch c
      when "#"
        prefix = true
      when "0"
        zero = true
      when " "
        zero = false
      when "+"
        sign = true
      when "-"
        lalign = true
        zero = false
  if width == ""
    width = 0
  else if width == "*"
    width = parseInt(values.shift()) or 0
  else
    width = parseInt(width)
  prec = if prec == "" then null else parseInt(prec.substr(1))
  return "%" if type == "%"
  p = ""
  s = ""
  v = values.shift()
  switch type
    when "d", "i", "u"
      break if isNaN(v = parseInt(v))
      prec = 1 unless prec?
      if prec == 0 and v == 0
        v = ""
        break
      s = if v < 0 then "-" else if sign then "+" else ""
      v = Math.abs(v).toString(10)
      v = "0#{v}" while v.length < prec
    when "o"
      break if isNaN(v = parseInt(v))
      prec = 0 unless prec?
      s = if v < 0 then "-" else if sign then "+" else ""
      v = Math.abs(v).toString(8)
      v = "0#{v}" while v.length < prec
      p = "0" if prefix and v[0] != "0"
    when "x", "X"
      break if isNaN(v = parseInt(v))
      prec = 0 unless prec?
      s = if v < 0 then "-" else if sign then "+" else ""
      v = Math.abs(v).toString(16)
      v = "0#{v}" while v.length < prec
      if type == "X"
        v = v.toUpperCase()
        p = "0X" if prefix
      else
        p = "0x" if prefix
    when "c"
      v = String.fromCharCode(parseInt(v))
    when "s"
      zero = false
  if lalign
    v = "#{s}#{p}#{v}"
    v = "#{v} " while v.length < width
  else if zero
    width -= (s.length + p.length)
    v = "0#{v}" while v.length < width
    v = "#{s}#{p}#{v}"
  else
    v = "#{s}#{p}#{v}"
    v = " #{v}" while v.length < width
  return v

module.exports = sprintf = (format, values...) ->
  return format.replace(RE, (args...) -> RP(values, args...))

