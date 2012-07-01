#= require modernizr.min.js
#= require jquery.min.js

window.log = ->
	if window.console
		window.console.log.apply window.console, arguments

(($) ->
	$splash = $(".splash")
	$body = $("body")

	init = ->
	 	# used to prevent transition "flashing" with -prefix-free
		$body.addClass("loaded")

		$(".drag-overlay").on "dragenter", dragStart
		$(".drag-overlay").on "dragleave", dragEnd
		$(".drag-overlay").on "drop", dragDrop
	
	dragStart = (e) ->
		$body.addClass("dragging")

	dragEnd = (e) ->
		$body.removeClass("dragging")

	dragDrop = (e) ->
		e.preventDefault()
		e.stopPropagation()
		dragEnd()


		for file in e.originalEvent.dataTransfer.files
			if /image/.test file.type 
				loadImage window.webkitURL.createObjectURL(file)
				return

		log "no images found"
		

	loadImage = (img) ->
		image = new Image()
		image.src = img
		$body.append image

	$ init
)(jQuery)
