
/**
 * Module dependencies.
 */

var express = require('express')
  , routes = require('./routes')
  , WebSocketServer = require('websocket').server
  , http = require('http');

var app = express(),
    clients = {},
    server;

app.configure(function(){
  app.set('port', process.env.PORT || 3000);
  app.set('views', __dirname + '/views');
  app.set('view engine', 'ejs');
  app.use(express.favicon());
  app.use(express.logger('dev'));
  app.use(express.limit('10mb'));
  //app.use(express.bodyParser());
  app.use(express.methodOverride());
  app.use(app.router);
  app.use(require('connect-assets')());
  app.use(express.static(__dirname + '/public'));
});

app.configure('development', function(){
  app.set('port', process.env.PORT || 4000);
  app.use(express.errorHandler());
});

app.get('/', routes.index({
  port: app.get("port")
}));
app.post('/upload', routes.upload({
  clients: clients
}));

server = http.createServer(app).listen(app.get('port'), function(){
  console.log("Express server listening on port " + app.get('port'));
});

wsServer = new WebSocketServer({
  httpServer: server,
  autoAcceptConnections: false
});

wsServer.on("request", function(req) {
  var connection = req.accept(null, req.origin),
      UUID = false,
      startTime,
      interval;
  // TODO: verify origin in production
  console.log("Socket connection accepted from " + req.origin);

  interval = setInterval(function() {
    startTime = startTime || Date.now();
    connection.sendUTF("Time: " + (Date.now() - startTime) / 1000);
  }, 500);
  connection.on("message", function(msg) {
    if (!UUID) {
      UUID = msg.utf8Data;
      clients[UUID] = connection;
    }
  });
  connection.on("close", function(reasonCode, description) {
    clearInterval(interval);
    console.log(connection.remoteAddress + " disconnected");
    if (UUID) {
      delete clients[UUID];
    }
  });
});