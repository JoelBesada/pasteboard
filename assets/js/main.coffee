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

	# Display welcome message (to users redirected from pasteshack.net)
	if window.location.hash is "#r"
		
		# Clear hash
		window.location.hash = ""
		if history and history.pushState
			history.pushState("", document.title, window.location.pathname)

		$(".welcome")
			.css("display", "block")
			.delay(1500)
			.transition(
				top: 0
				opacity: 1
			)

	# Analytics
	if window._gaq
		$(".source").on "click", () ->
			_gaq.push ['_trackEvent', 'main page', 'click', 'github link']

		$(".author a").on "click", () ->
			_gaq.push ['_trackEvent', 'main page', 'click', 'twitter link']
