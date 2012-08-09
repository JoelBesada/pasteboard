### 
# Socket connection module, primarily used to
# detect when a user leaves the page
###

ID = false
socketConnection = (pasteboard) ->
	self = 
		isSupported: () -> !!window.WebSocket
		getID: () -> return ID
		init: () ->
			connection = new WebSocket("ws://#{window.location.hostname}:#{SOCKET_PORT}")
			connection.onmessage = (e) ->
				try
					data = JSON.parse(e.data)
				catch err
					data = e.data

				if not ID and data.id
					ID = data.id
					$(self).trigger("idReceive")
				else
					log e.data

window.moduleLoader.addModule "socketConnection", socketConnection
