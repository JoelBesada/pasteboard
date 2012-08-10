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

		for file in e.originalEvent.dataTransfer.files
			if /image/.test file.type
				pasteboard.fileHandler.readFile file
				return

		pasteboard.noImageError()


	self = 
		isSupported: () -> Modernizr.draganddrop and pasteboard.fileHandler.isSupported()
		# Initializes the module
		init: () ->
			return unless this.isSupported()
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
