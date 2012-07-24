(($) ->
	pasteBoard.dragAndDrop = (() ->
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
			supported:  Modernizr.draganddrop and pasteBoard.fileReadSupport
			init: () ->
				return unless this.supported
				$body.prepend $dropArea

				$dropArea.on
						"dragenter": onDragStart
						"dragleave": onDragEnd
						"dragover": onDragOver
						"drop": onDragDrop
			hide: () ->
				$dropArea.hide()
		
	)() 
)(jQuery)
