(($) ->
	pasteBoard.copyAndPaste = (() ->
		pasteArea = $("<div>")
						.attr("contenteditable", "")
						.css( "opacity", 0)
		onPaste = (e) ->
			if e.originalEvent.clipboardData
				return unless e.originalEvent.clipboardData.items
				for item in e.originalEvent.clipboardData.items
					if /image/.test item.type
						pasteBoard.fileHandler.readFile item.getAsFile()
						return

				pasteBoard.noImageError()
			else 
				setTimeout parsePaste, 1

		parsePaste = () ->
			child = pasteArea[0].childNodes[0]
			pasteArea.html("")

			if child 
				if child.tagName is "IMG"
					pasteBoard.imageEditor.init child.src
					return

			pasteBoard.noImageError()
		

		self = 
			init: () ->
				unless window.Clipboard and pasteBoard.fileReadSupport
					pasteArea
						.appendTo("body")
						.focus()

					$(document).on "click", () -> pasteArea.focus() 
			
				$(window).on "paste", onPaste
			hide: () ->
				# ... 		
	)() 
)(jQuery)
