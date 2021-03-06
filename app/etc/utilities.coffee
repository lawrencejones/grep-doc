# Useful utility helpers to augment typical js routines

# Adds eq-like selection.
cheerio = require 'cheerio'
cheerio::elemAt = (sel, i) ->
  (@find sel).eq i

Date::toJSON = Date::getTime

# Adds extend to Object
Object.extend = (dst, src) ->
  dst[k] = v for own k,v of src
  dst

# Allows pushing to an array if element is not already present.
Array::addUnique = (elem, eq = ((a,b) -> a == b)) ->
  found = false
  found |= eq _elem, elem for _elem in @
  @push elem if not found

Array::mergeUnique = (array, eq) ->
  for elem in array
    @addUnique elem, eq
  return @

Array::any = (f = (e) -> e) ->
  for e in @
    return true if f e
  false

Array::modify = (f) ->
  if typeof f == 'function'
    @[i] = f e for e,i in @
  return @

Array::select = (f) ->
  if typeof f == 'function'
    j = 0
    for e,i in @
      if !f(e) then @splice (i - j++), 1
  return @
