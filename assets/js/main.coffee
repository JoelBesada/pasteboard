#= require common
#= require_tree lib
#= require modules/moduleloader
#= require_tree modules

# Global console.log shorthand
window.log = ->
	if window.console
		window.console.log.apply window.console, arguments

pasteboard = {}

window.moduleLoader.loadAll(pasteboard)

$ () ->
	pasteboard.appFlow.start()

	# Analytics
	if window._gaq
		$(".source").on "click", () ->
			_gaq.push ['_trackEvent', 'main page', 'click', 'github link']

		$(".author a").on "click", () ->
			_gaq.push ['_trackEvent', 'main page', 'click', 'twitter link']
