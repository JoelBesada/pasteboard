connectCache = require '../lib/cache'
cache = connectCache()

exports['set converts strings to buffers'] = (test) ->
  cache.set 'a', 'str1'
  cache.set 'b', new Buffer('str2')
  test.ok cache.get('a') instanceof Buffer
  test.equal cache.get('a').toString('utf8'), 'str1'
  test.ok cache.get('b') instanceof Buffer
  test.equal cache.get('b').toString('utf8'), 'str2'
  test.done()

exports['set updates cache mtime, rounded to earlier second'] = (test) ->
  cache.set 'c', 'str1'
  mtime1 = cache.map['/c'].mtime
  setTimeout ( ->
    cache.set 'c', 'str2'
    mtime2 = cache.map['/c'].mtime
    test.ok mtime2 > mtime1
    test.done()
  ), 1000