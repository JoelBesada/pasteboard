request      = require 'request'
connect      = require 'connect'
connectCache = require '../lib/cache.js'
fs           = require 'fs'

cache = connectCache src: '../test_fixtures'
app = connect.createServer()
app.use cache.middleware
app.listen 3688

exports['Data with no extension is served properly'] = (test) ->
  cache.set 'i18n/klingon/success', 'Qapla!'

  request 'http://localhost:3688/i18n/klingon/success', (err, res, body) ->
    test.equals body, 'Qapla!'
    test.done()

exports['Files are cached after being served'] = (test) ->
  request 'http://localhost:3688/popeye-zen.txt', (err, res, body) ->
    test.equals body, 'I am what I am.'
    test.equals res.headers['content-type'], 'text/plain'
    test.ok cache.get('/popeye-zen.txt')

    request 'http://localhost:3688/popeye-zen.txt', (err, res, body) ->
      test.equals body, 'I am what I am.'
      test.equals res.headers['content-type'], 'text/plain'
      test.done()

exports['Conditional GET can yield a 304 response for files'] = (test) ->
  request 'http://localhost:3688/popeye-zen.txt', (err, res, body) ->
    mtime = res.headers['last-modified']

    options =
      url: 'http://localhost:3688/popeye-zen.txt'
      headers: {'If-Modified-Since': mtime}
    request options, (err, res, body) ->
      test.equals body, ''
      test.equals res.statusCode, 304
      test.done()

exports['Conditional GET can yield a 304 response for set data'] = (test) ->
  cache.set('newroute.txt', 'some text', mtime: new Date)

  request 'http://localhost:3688/newroute.txt', (err, res, body) ->
    test.equals body, 'some text'
    test.equals res.statusCode, 200
    mtime = res.headers['last-modified']

    options =
      url: 'http://localhost:3688/newroute.txt'
      headers: {'If-Modified-Since': mtime}
    request options, (err, res, body) ->
      test.equals body, ''
      test.equals res.statusCode, 304
      test.done()

exports['Cache is invalidated when file has changed'] = (test) ->
  request 'http://localhost:3688/raven-quoth.html', (err, res, body) ->
    test.equals body, 'Evermore'
    test.equals res.headers['content-type'], 'text/html'
    test.equals cache.get('/raven-quoth.html').toString('utf8'), 'Evermore'
    mtime1 = cache.map['/raven-quoth.html'].mtime
    test.equals res.headers['last-modified'], mtime1.toUTCString()
    fs.writeFileSync '../test_fixtures/raven-quoth.html', 'Nevermore'

    options =
      url: 'http://localhost:3688/raven-quoth.html'
      headers: {'If-Modified-Since': mtime1}
    request options, (err, res, body) ->
      test.equals body, 'Nevermore'
      test.equals cache.get('/raven-quoth.html').toString('utf8'), 'Nevermore'
      mtime2 = cache.map['/raven-quoth.html'].mtime
      test.equals res.headers['last-modified'], mtime2.toUTCString()
      test.ok mtime2 > mtime1
      fs.writeFileSync '../test_fixtures/raven-quoth.html', 'Evermore'
      test.done()

exports['Files are gzip-compressed if (and only if) supported'] = (test) ->
  request 'http://localhost:3688/lorem.txt', (err, res, originalBody) ->
    test.ok !res.headers['content-encoding']

    options =
      url: 'http://localhost:3688/lorem.txt'
      headers: {'Accept-Encoding': 'gzip'}
    request options, (err, res, gzippedBody) ->
      test.ok gzippedBody.length < originalBody.length
      test.equals res.headers['content-encoding'], 'gzip'
      test.done()