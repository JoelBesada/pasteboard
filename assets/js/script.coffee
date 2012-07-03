#= require modernizr.min.js
#= require jquery.min.js

window.log = ->
	if window.console
		window.console.log.apply window.console, arguments

(($) ->
	$body = $ "body"
	$splash = $ ".splash"
	$dragOverlay = $ ".drag-overlay"
	dndSupport = true
	clipboardSupport = true
	pasteTarget = null

	init = ->
	 	# used to prevent transition "flashing" with -prefix-free
		$body.addClass "loaded"

		detectSupport()

		if dndSupport
			$dragOverlay.on 
				"dragenter": onDragStart
				"dragleave": onDragEnd
				"dragover": onDragOver
				"drop": onDragDrop

		unless window.Clipboard and fileReadSupport()
			pasteTarget = $("<div>")
							.attr("contenteditable", "")
							.css( 
								"opacity" : 0
							)
							.appendTo("body")
							.focus()

			$(document).on "click", () -> pasteTarget.focus() 
			
		$(window).on "paste", onPaste
	
	onDragStart = (e) ->
		$body.addClass "dragging"	

	onDragEnd = (e) ->
		$body.removeClass "dragging"

	onDragOver = (e) ->
		e.stopPropagation();
		e.preventDefault();
		e.originalEvent.dataTransfer.dropEffect = 'copy';

	onDragDrop = (e) ->
		e.preventDefault()
		e.stopPropagation()
		$body.removeClass "dragging"


		for file in e.originalEvent.dataTransfer.files
			if /image/.test file.type
				readFile file
				return

		noImageError()
	
	onPaste = (e) ->
		if e.originalEvent.clipboardData
			return unless e.originalEvent.clipboardData.items
			for item in e.originalEvent.clipboardData.items
				if /image/.test item.type
					readFile item.getAsFile()
					return

			noImageError()
		else 
			setTimeout parsePaste, 1


	parsePaste = () ->
		child = pasteTarget[0].childNodes[0]
		pasteTarget.html("")

		if child 
			if child.tagName is "IMG"
				loadImage child.src
				return

		noImageError()

	readFile = (file) ->
		if window.FileReader
			fileReader = new FileReader()
			fileReader.onload = (e) ->
				loadImage e.target.result

			fileReader.readAsDataURL file
			return true
		else if url = window.URL || window.webkitURL
			loadImage url.createObjectURL(file)
			return true

		return false


	loadImage = (img) ->
		image = new Image()
		image.src = img
		$body.append image
		$dragOverlay.hide()
		$splash.hide()

	detectSupport = () ->
		noDnDSupport() unless Modernizr.draganddrop and fileReadSupport()
							 

	fileReadSupport = () ->
		window.FileReader or window.URL or window.webkitURL

	noDnDSupport = () ->
		dndSupport = false

	noImageError = () ->
		log "no images found"

	$ init
)(jQuery)
