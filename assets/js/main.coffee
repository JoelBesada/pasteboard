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

# Load the "about" text and display the modal when clicking the button
loadAbout = ->
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

# Load the recent uploads template and display the modal
# when clicking the button, unless there are no recent uploads
loadUploads = ->
	return unless window.RECENT_UPLOADS.length

	pasteboard.template.compile \
		"jstemplates/uploads.tmpl",
		{ images: window.RECENT_UPLOADS },
		(compiledTemplate) ->
			$(".show-uploads").addClass "show"
			$(document).on "click", ".show-uploads", (e) ->
				e.preventDefault()
				pasteboard.modalWindow.show "uploads",
					content: compiledTemplate
					showClose: true

# Display welcome message (to users redirected from pasteshack.net)
displayRedirectWelcome = ->
	if $(".welcome").length > 0
		$(".welcome")
			.css("display", "block")
			.delay(1500)
			.transition(
				top: 0
				opacity: 1
			)

$ () ->
	pasteboard.analytics.init()
	pasteboard.appFlow.start()

	loadAbout()
	loadUploads()
	displayRedirectWelcome()
