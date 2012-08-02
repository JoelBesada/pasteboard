
### 
# Drag and Drop module, handles drag / drop events
# and sends the dropped image to the editor.
###

(($) ->
	pasteBoard.dragAndDrop = (() ->
		firstInit = true
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

			for file in e.originalEvent.dataTransfer.files
				if /image/.test file.type
					pasteBoard.fileHandler.readFile file
					return

			pasteBoard.noImageError()
	

		self = 
			isSupported: () -> Modernizr.draganddrop and pasteBoard.fileHandler.isSupported()
			# Initializes the module
			init: () ->
				return unless this.isSupported()
				$body.prepend $dropArea
				if firstInit
					$dropArea.on
							"dragenter": onDragStart
							"dragleave": onDragEnd
							"dragover": onDragOver
							"drop": onDragDrop
					firstInit = false
			
			# Hides the elements related to the module
			# and stops event listeners
			hide: () ->
				$dropArea.detach()
		
	)() 
)(jQuery)
