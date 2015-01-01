class Comm
  @list: []
  @add: (subclass) -> @list.push(subclass)
  @load: (data) -> Marshal.load(data, @list)
