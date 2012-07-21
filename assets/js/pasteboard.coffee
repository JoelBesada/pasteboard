(($) ->
	window.log = ->
		if window.console
			window.console.log.apply window.console, arguments

	window.PasteBoard = 
		fileReadSupport: window.FileReader or window.URL or window.webkitURL
		UUID: "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx".replace(/[xy]/g, (c) ->
				  r = Math.random() * 16 | 0
				  v = (if c is "x" then r else (r & 0x3 | 0x8))
				  v.toString 16)
		
		noImageError: () ->
			log "no images found"


)(jQuery)