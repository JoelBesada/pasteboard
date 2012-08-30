### 
# Drag and Drop module, handles drag / drop events
# and sends the dropped image to the editor.
###
dragAndDrop = (pasteboard) ->
	$body = $ "body"
	$dropArea = $("<div>")
					.addClass("drop-area")

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

		# Look for files
		for file in e.originalEvent.dataTransfer.files
			if /image/.test file.type
				pasteboard.fileHandler.readFile file, drop: true
				return

		# Look for HTML data
		if htmlData = e.originalEvent.dataTransfer.getData("text/html")
			foundImage = false
			# Loop through everything in the dragged in HTML data to search for images
			$(htmlData).each(() ->
				if this.tagName is "IMG" and this.src
					img = this
				else 
					img = $(this).find("img")[0]

				if img
					# Base64 encoded
					if /^data:image/i.test img.src
						pasteboard.fileHandler.readData img.src, drop: true
						foundImage = true
						return false
					# External image URL
					if /^http(s?):\/\//i.test img.src
						pasteboard.fileHandler.readExternalImage img.src, drop: true
						foundImage = true
						return false

			)
			return if foundImage

		# Look for plain text data
		if textData = e.originalEvent.dataTransfer.getData("text/plain")
			# Base64 encoded
			if /^data:image/i.test img.src
				pasteboard.fileHandler.readData textData, drop: true
				return

			# External image URL
			if /^http(s?):\/\//i.test textData
				pasteboard.fileHandler.readExternalImage textData, drop: true
				return

		$(pasteboard).trigger "noimagefound", drop: true

	self = 
		isSupported: () -> !!(Modernizr.draganddrop and pasteboard.fileHandler.isSupported())
		# Initializes the module
		init: () ->
			unless @isSupported()
				$("html").addClass("no-draganddrop-pb") # add -pb to prevent conflict with Modernizr
				return

			$body.prepend $dropArea
			$dropArea.on
					"dragenter.dragevent": onDragStart
					"dragleave.dragevent": onDragEnd
					"dragover.dragevent": onDragOver
					"drop.dragevent": onDragDrop
		
		# Hides the elements related to the module
		# and stops event listeners
		hide: () ->
			$dropArea.off(".dragevent")
			$dropArea.detach()
	

window.moduleLoader.addModule "dragAndDrop", dragAndDrop
