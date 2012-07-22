(($) ->
	window.log = ->
		if window.console
			window.console.log.apply window.console, arguments

	window.PasteBoard = 
		fileReadSupport: window.FileReader or window.URL or window.webkitURL
		noImageError: () ->
			log "no images found"


)(jQuery)