Z2 = (value) -> return "0#{value.toString(10)}".substr(-2)
S2 = (value) -> return " #{value.toString(10)}".substr(-2)
RE = /%([CdDeHImMnRStTuwyY%])/g
RP = (fmt, date) ->
  switch fmt
    when "C" then return Z2(Math.floor(date.getFullYear() / 100))
    when "d" then return Z2(date.getDate())
    when "D" then return "#{RP("m", date)}/#{RP("d", date)}/#{RP("y", date)}"
    when "e" then return S2(date.getDate())
    when "H" then return Z2(date.getHours())
    when "I" then return Z2(((date.getHours() + 11) % 12) + 1)
    when "m" then return Z2(date.getMonth() + 1)
    when "M" then return Z2(date.getMinutes())
    when "n" then return "\n"
    when "R" then return "#{RP("H", date)}:#{RP("M", date)}"
    when "S" then return Z2(date.getSeconds())
    when "t" then return "\t"
    when "T" then return "#{RP("H", date)}:#{RP("M", date)}:#{RP("S", date)}"
    when "u" then return (((date.getDay() + 6) % 7) + 1).toString(10)
    when "w" then return date.getDay().toString(10)
    when "y" then return Z2(date.getYear() % 100)
    when "Y" then return date.getFullYear().toString(10)
    when "%" then return "%"

strftime = (format, date) ->
  date or= new Date()
  return format.replace(RE, (match, fmt) -> RP(fmt, date))

module.exports = strftime
