
### 
# Copy and Paste module, handles paste events
# and sends the pasted image to the editor.
#
# This technique is described in a blog post I've written: 
# http://joelb.me/blog/2011/code-snippet-accessing-clipboard-images-with-javascript/
###

(($) ->
	pasteBoard.copyAndPaste = (() ->
		pasteArea = $("<div>")
						.attr("contenteditable", "")
						.css( "opacity", 0)
		onPaste = (e) ->
			if e.originalEvent.clipboardData
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
		
		focusPasteArea = () ->
			pasteArea.focus() 

		self = 
			# Initializes the module
			init: () ->
				# Clipboard fallback
				unless window.Clipboard and pasteBoard.fileReadSupport
					pasteArea
						.appendTo("body")
						.focus()

					$(document).on "click", focusPasteArea
			
				$(window).on "paste", onPaste

			# Hides the elements related to the module
			# and stops event listeners
			hide: () ->
				pasteArea.remove()
				$(window).off "paste", onPaste
				$(document).off "click", focusPasteArea


	)() 
)(jQuery)
