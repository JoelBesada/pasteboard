###
# WebSocket Server Setup
#
# Sockets are used to detect when users leave the web
# page so that temporary data can be removed
###
WebSocketServer = require("websocket").server
app = null
clients = {}

exports.init = (expressApp, webServer) ->
  app = expressApp
  app.set "clients", clients

  webSocketServer = new WebSocketServer
    httpServer: webServer
    autoAcceptConnections: false

  webSocketServer.on "request", (req) ->
    ID = generateID()
    if originIsAllowed req.origin
      connection = req.accept null, req.origin

      # Send the ID to the client
      connection.sendUTF JSON.stringify(id: ID)
      clients[ID] =
        connection: connection,
        file: false
        uploading: {}

      connection.on "close", (reasonCode, description) ->
        if clients[ID]?.file
          # Delete the leftover file
          (require "fs").unlink clients[ID].file.path
        delete clients[ID]

    else
      console.log "Socket connection denied from #{req.origin}"

# Generate an unique ID for clients connecting to the server
# http://stackoverflow.com/a/2117523
generateID = ->
  "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx".replace /[xy]/g, (c) ->
          r = Math.random() * 16 | 0
          v = (if c is "x" then r else (r & 0x3 | 0x8))
          return v.toString 16

originIsAllowed = (origin) ->
  app.get("localrun") or origin is app.get "domain"
