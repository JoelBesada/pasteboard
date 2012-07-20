
/**
 * Module dependencies.
 */

var express = require('express')
  , routes = require('./routes')
  , http = require('http');

var app = express();

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
  app.set('port', 4000);
  app.use(express.errorHandler());
});

app.get('/', routes.index);
app.post('/upload', routes.upload);

http.createServer(app).listen(app.get('port'), function(){
  console.log("Express server listening on port " + app.get('port'));
});
