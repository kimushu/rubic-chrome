Map::toJSON or= ->
  array = []
  @forEach((value, key) -> array.push([key, value]))
  return array

Map.fromJSON or= (array) ->
  return new this(array)

