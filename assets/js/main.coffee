#= require common
#= require_tree lib
#= require moduleloader
#= require_tree .

# Global console.log shorthand
window.log = ->
	if window.console
		window.console.log.apply window.console, arguments

pasteboard = 
	imageURL: (url) -> window.location.href + url
	noImageError: () ->
		log "no images found"

window.moduleLoader.loadAll(pasteboard)

$ () ->
	pasteboard.appFlow.start()

