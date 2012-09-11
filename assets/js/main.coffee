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
	pasteboard.analytics.init()
	pasteboard.appFlow.start()

	# Display welcome message (to users redirected from pasteshack.net)
	if $(".welcome").length > 0
		$(".welcome")
			.css("display", "block")
			.delay(1500)
			.transition(
				top: 0
				opacity: 1
			)

	# Load the "about" text and display the modal when clicking the button
	pasteboard.template.compile \
		"jstemplates/about.tmpl", 
		{}, 
		(compiledTemplate) ->
			$(document).on "click", ".show-about", (e) ->
				e.preventDefault()
				pasteboard.modalWindow.show "text", 
						content: compiledTemplate
						showClose: true
					, (modal) ->
						aboutModal = modal
		    



	
