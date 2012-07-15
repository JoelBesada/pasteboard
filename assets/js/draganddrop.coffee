(($) ->
	PasteBoard.DragAndDrop = (() ->
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
					PasteBoard.FileHandler.readFile file
					return

			PasteBoard.noImageError()
	

		self = 
			supported:  Modernizr.draganddrop and PasteBoard.fileReadSupport
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
