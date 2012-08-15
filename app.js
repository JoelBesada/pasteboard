
/**
 * Module dependencies.
 */

var express = require('express')
  , routes = require('./routes')
  , WebSocketServer = require('websocket').server
  , fs = require('fs')
  , http = require('http');

var app = express(),
    clients = {},
    server,
    wsServer;

app.configure(function(){
  app.set('port', process.env.PORT || 3000);
  app.set('clients', clients);
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

app.get('/', routes.index);
app.get('/:image', routes.image);
app.post('/upload', routes.upload);
app.post('/preupload', routes.preupload);
app.post('/clearfile', routes.clearfile);

server = http.createServer(app).listen(app.get('port'), function(){
  console.log("Express server listening on port " + app.get('port'));
});

// The websocket server is primarily needed to determine
// when users disconnect so that temporary data can be deleted
wsServer = new WebSocketServer({
  httpServer: server,
  autoAcceptConnections: false
});

wsServer.on("request", function(req) {
  var connection,
      ID = "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx".replace(/[xy]/g, function(c) {
          var r = Math.random() * 16 | 0,
              v = (c === "x" ? r : (r & 0x3 | 0x8));
          return v.toString(16);
      });

  if (originIsAllowed(req.origin)) {
    connection = req.accept(null, req.origin);

    // Send the ID to the client
    connection.sendUTF(JSON.stringify({ id: ID }));
    clients[ID] = {
      connection: connection,
      file: false,
      uploading: {}
    };

    connection.on("close", function(reasonCode, description) {
        if (clients[ID] && clients[ID].file) {
          // Delete leftover file
          fs.unlink(clients[ID].file.path);
        }
        delete clients[ID];
    });
  } else {
    console.log("Socket connection denied from " + req.origin);
  }
});

function originIsAllowed(origin) {
  if (process.env.LOCAL) return true;
  if (app.get("env") === "development") return origin === "http://dev.pasteboard.me";
  return origin === "http://pasteboard.me";
}