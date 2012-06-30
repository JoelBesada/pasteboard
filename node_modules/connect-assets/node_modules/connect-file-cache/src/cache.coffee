# [connect-file-cache](http://github.com/TrevorBurnham/connect-file-cache)

fs             = require 'fs'
mime           = require 'mime'
path           = require 'path'
_              = require 'underscore'
{parse}        = require 'url'
{gzip}         = require 'zlib'

# options:
# * `src`: A dir containing files to be served directly (defaults to `null`)
# * `routePrefix`: Data will be served from this path (defaults to `/`)
module.exports = (options = {}) -> new ConnectFileCache(options)

class ConnectFileCache
  constructor: (@options, @map = {}) ->
    @options.src ?= null
    @options.routePrefix ?= '/'

  # Handle incoming requests
  middleware: (req, res, next) =>
    return next() unless req.method is 'GET'
    route = parse(req.url).pathname
    @loadFile route, =>
      if @map[route]
        @serveBuffer req, res, next, {route}
      else
        next()

  # If a file corresponding to the given route exists, load it in the cache
  loadFile: (route, callback) ->
    return callback() unless @options.src
    filePath = path.join process.cwd(), @options.src, route
    fs.stat filePath, (err, stats) =>
      return callback() if err  # no matching file exists
      cacheTimestamp = @map[route]?.mtime
      if cacheTimestamp and (stats.mtime <= cacheTimestamp)
        callback()
      else
        fs.readFile filePath, (err, data) =>
          throw err if err
          @set route, data, mtime: stats.mtime
          callback()

  serveBuffer: (req, res, next, {route}) ->
    cacheHash = @map[route]
    cacheTimestamp = cacheHash.mtime
    if cacheTimestamp and req.headers['if-modified-since']
      clientTimestamp = new Date(req.headers['if-modified-since'])
      unless isNaN clientTimestamp.getTime()
        unless cacheTimestamp > clientTimestamp
          res.statusCode = 304
          return res.end()

    {flags} = _.defaults cacheHash, flags: {}
    res.setHeader 'Content-Type', flags.mime ? mime.lookup(route)
    res.setHeader 'Expires', FAR_FUTURE_EXPIRES if flags.expires is false
    res.setHeader 'Last-Modified', cacheTimestamp.toUTCString()
    if flags.attachment is true
      filename = path.basename(route)
      contentDisposition = 'attachment; filename="' + filename + '"'
      res.setHeader 'Content-Disposition', contentDisposition

    if cacheHash.gzippedData and req.headers['accept-encoding']?.indexOf /gzip/
      res.setHeader 'Content-Encoding', 'gzip'
      res.setHeader 'Content-Length', cacheHash.gzippedData.length
      res.end cacheHash.gzippedData
    else
      res.setHeader 'Content-Length', cacheHash.data.length
      res.end cacheHash.data

  # Manage data directly, without physical files
  set: (routes, data, flags = {}) ->
    routes = [routes] unless routes instanceof Array
    data = new Buffer(data) unless data instanceof Buffer
    millis = 1000 * Math.floor (flags.mtime ? new Date()).getTime() / 1000
    mtime = new Date(millis)
    for route in routes
      flags = _.extend {}, flags
      @map[normalizeRoute route] = {data, flags, mtime}
      if data.length >= MIN_GZIP_SIZE
        gzip data, (err, gzippedData) =>
          @map[normalizeRoute route].gzippedData = gzippedData
    @

  remove: (routes) ->
    routes = [routes] unless routes instanceof Array
    delete @map[normalizeRoute route] for route in routes
    @

  get: (route) ->
    @map[normalizeRoute route]?.data

  getMtime: (route) ->
    @map[normalizeRoute route]?.mtime

# constants
FAR_FUTURE_EXPIRES = "Wed, 01 Feb 2034 12:34:56 GMT"
MIN_GZIP_SIZE = 200

# utility functions
normalizeRoute = (route) ->
  route = "/#{route}" unless route[0] is '/'
  route
