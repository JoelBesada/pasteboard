
### 
#	Application main module, all other modules
#	are attached to this one for global access.
#
#   Also adds the global log() shorthand function 
###

(($) ->
	window.log = ->
		if window.console
			window.console.log.apply window.console, arguments

	window.pasteboard = 
		noImageError: () ->
			log "no images found"

)(jQuery)