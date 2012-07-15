(($) ->
	PasteBoard.CopyAndPaste = (() ->
		pasteArea = $("<div>")
						.attr("contenteditable", "")
						.css( "opacity", 0)
		onPaste = (e) ->
			if e.originalEvent.clipboardData
				return unless e.originalEvent.clipboardData.items
				for item in e.originalEvent.clipboardData.items
					if /image/.test item.type
						PasteBoard.FileHandler.readFile item.getAsFile()
						return

				PasteBoard.noImageError()
			else 
				setTimeout parsePaste, 1

		parsePaste = () ->
			child = pasteArea[0].childNodes[0]
			pasteArea.html("")

			if child 
				if child.tagName is "IMG"
					PasteBoard.ImageEditor.init child.src
					return

			PasteBoard.noImageError()
		

		self = 
			init: () ->
				unless window.Clipboard and PasteBoard.fileReadSupport
					pasteArea
						.appendTo("body")
						.focus()

					$(document).on "click", () -> pasteArea.focus() 
			
				$(window).on "paste", onPaste
			hide: () ->
				# ... 		
	)() 
)(jQuery)
