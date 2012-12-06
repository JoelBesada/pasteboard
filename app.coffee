###
# Express Bootstrap
###
express = require "express"
http = require "http"
async = require "async"

app = express()

(require "./config/environments").init  app, express
(require "./config/routes").init		app

http.createServer(app).listen(app.get('port'), ->
	console.log("Express server listening on port " + app.get('port'))
)
