(function() {
  var ConnectFileCache, FAR_FUTURE_EXPIRES, MIN_GZIP_SIZE, fs, gzip, mime, normalizeRoute, parse, path, _;
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  fs = require('fs');

  mime = require('mime');

  path = require('path');

  _ = require('underscore');

  parse = require('url').parse;

  gzip = require('zlib').gzip;

  module.exports = function(options) {
    if (options == null) options = {};
    return new ConnectFileCache(options);
  };

  ConnectFileCache = (function() {

    function ConnectFileCache(options, map) {
      var _base, _base2, _ref, _ref2;
      this.options = options;
      this.map = map != null ? map : {};
      this.middleware = __bind(this.middleware, this);
      if ((_ref = (_base = this.options).src) == null) _base.src = null;
      if ((_ref2 = (_base2 = this.options).routePrefix) == null) {
        _base2.routePrefix = '/';
      }
    }

    ConnectFileCache.prototype.middleware = function(req, res, next) {
      var route;
      var _this = this;
      if (req.method !== 'GET') return next();
      route = parse(req.url).pathname;
      return this.loadFile(route, function() {
        if (_this.map[route]) {
          return _this.serveBuffer(req, res, next, {
            route: route
          });
        } else {
          return next();
        }
      });
    };

    ConnectFileCache.prototype.loadFile = function(route, callback) {
      var filePath;
      var _this = this;
      if (!this.options.src) return callback();
      filePath = path.join(process.cwd(), this.options.src, route);
      return fs.stat(filePath, function(err, stats) {
        var cacheTimestamp, _ref;
        if (err) return callback();
        cacheTimestamp = (_ref = _this.map[route]) != null ? _ref.mtime : void 0;
        if (cacheTimestamp && (stats.mtime <= cacheTimestamp)) {
          return callback();
        } else {
          return fs.readFile(filePath, function(err, data) {
            if (err) throw err;
            _this.set(route, data, {
              mtime: stats.mtime
            });
            return callback();
          });
        }
      });
    };

    ConnectFileCache.prototype.serveBuffer = function(req, res, next, _arg) {
      var cacheHash, cacheTimestamp, clientTimestamp, contentDisposition, filename, flags, route, _ref, _ref2;
      route = _arg.route;
      cacheHash = this.map[route];
      cacheTimestamp = cacheHash.mtime;
      if (cacheTimestamp && req.headers['if-modified-since']) {
        clientTimestamp = new Date(req.headers['if-modified-since']);
        if (!isNaN(clientTimestamp.getTime())) {
          if (!(cacheTimestamp > clientTimestamp)) {
            res.statusCode = 304;
            return res.end();
          }
        }
      }
      flags = _.defaults(cacheHash, {
        flags: {}
      }).flags;
      res.setHeader('Content-Type', (_ref = flags.mime) != null ? _ref : mime.lookup(route));
      if (flags.expires === false) res.setHeader('Expires', FAR_FUTURE_EXPIRES);
      res.setHeader('Last-Modified', cacheTimestamp.toUTCString());
      if (flags.attachment === true) {
        filename = path.basename(route);
        contentDisposition = 'attachment; filename="' + filename + '"';
        res.setHeader('Content-Disposition', contentDisposition);
      }
      if (cacheHash.gzippedData && ((_ref2 = req.headers['accept-encoding']) != null ? _ref2.indexOf(/gzip/) : void 0)) {
        res.setHeader('Content-Encoding', 'gzip');
        res.setHeader('Content-Length', cacheHash.gzippedData.length);
        return res.end(cacheHash.gzippedData);
      } else {
        res.setHeader('Content-Length', cacheHash.data.length);
        return res.end(cacheHash.data);
      }
    };

    ConnectFileCache.prototype.set = function(routes, data, flags) {
      var millis, mtime, route, _i, _len, _ref;
      var _this = this;
      if (flags == null) flags = {};
      if (!(routes instanceof Array)) routes = [routes];
      if (!(data instanceof Buffer)) data = new Buffer(data);
      millis = 1000 * Math.floor(((_ref = flags.mtime) != null ? _ref : new Date()).getTime() / 1000);
      mtime = new Date(millis);
      for (_i = 0, _len = routes.length; _i < _len; _i++) {
        route = routes[_i];
        flags = _.extend({}, flags);
        this.map[normalizeRoute(route)] = {
          data: data,
          flags: flags,
          mtime: mtime
        };
        if (data.length >= MIN_GZIP_SIZE) {
          gzip(data, function(err, gzippedData) {
            return _this.map[normalizeRoute(route)].gzippedData = gzippedData;
          });
        }
      }
      return this;
    };

    ConnectFileCache.prototype.remove = function(routes) {
      var route, _i, _len;
      if (!(routes instanceof Array)) routes = [routes];
      for (_i = 0, _len = routes.length; _i < _len; _i++) {
        route = routes[_i];
        delete this.map[normalizeRoute(route)];
      }
      return this;
    };

    ConnectFileCache.prototype.get = function(route) {
      var _ref;
      return (_ref = this.map[normalizeRoute(route)]) != null ? _ref.data : void 0;
    };

    ConnectFileCache.prototype.getMtime = function(route) {
      var _ref;
      return (_ref = this.map[normalizeRoute(route)]) != null ? _ref.mtime : void 0;
    };

    return ConnectFileCache;

  })();

  FAR_FUTURE_EXPIRES = "Wed, 01 Feb 2034 12:34:56 GMT";

  MIN_GZIP_SIZE = 200;

  normalizeRoute = function(route) {
    if (route[0] !== '/') route = "/" + route;
    return route;
  };

}).call(this);
