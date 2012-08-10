### 
# Copy and Paste module, handles paste events
# and sends the pasted image to the editor.
#
# This technique is described in a blog post I've written: 
# http://joelb.me/blog/2011/code-snippet-accessing-clipboard-images-with-javascript/
###

copyAndPaste = (pasteboard) ->
	pasteArea = $("<div>")
					.attr("contenteditable", "")
					.css( "opacity", 0)
	onPaste = (e) ->
		if e.originalEvent.clipboardData
			for item in e.originalEvent.clipboardData.items
				if /image/.test item.type
					pasteboard.fileHandler.readFile item.getAsFile()
					return

			pasteboard.noImageError()
		else 
			setTimeout parsePaste, 1

	parsePaste = () ->
		child = pasteArea[0].childNodes[0]
		pasteArea.html("")

		if child 
			if child.tagName is "IMG"
				pasteboard.fileHandler.readData child.src
				return

		pasteboard.noImageError()
	
	focusPasteArea = () ->
		pasteArea.focus() 

	self = 
		# Initializes the module
		init: () ->
			# Clipboard fallback
			unless window.Clipboard
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


window.moduleLoader.addModule "copyAndPaste", copyAndPaste
