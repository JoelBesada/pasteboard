#= require_tree lib
#= require pasteboard
#= require_tree .


(($) ->

	$ ->
	 	# used to prevent transition "flashing" with -prefix-free
		$("body").addClass "loaded"

		PasteBoard.DragAndDrop.init()
		PasteBoard.CopyAndPaste.init()
		connection = new WebSocket("ws://#{window.location.hostname}:#{SOCKET_PORT}")
		connection.onopen = () ->
			connection.send(PasteBoard.UUID);
		connection.onmessage = (msg) ->
			console.log(msg.data)

)(jQuery)

