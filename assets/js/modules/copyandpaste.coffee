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

	usePasteArea = (->
		$.browser.mozilla
	)()

	onPaste = (e) ->
		if usePasteArea
			setTimeout parsePaste, 1
		else
			items = e.originalEvent.clipboardData.items
			unless items
				$("html").addClass("no-copyandpaste")
				return

			for item in items
				if /image/.test item.type
					pasteboard.fileHandler.readFile item.getAsFile(), paste: true
					return

			$(pasteboard).trigger "noimagefound", paste: true

	parsePaste = () ->
		child = pasteArea[0].childNodes[0]
		pasteArea.html("")

		if child and child.tagName is "IMG"
			# Base64 encoded
			if /^data:image/i.test child.src
				pasteboard.fileHandler.readData child.src, paste: true
				return
			# External image URL
			else if /^http(s?):\/\//i.test child.src
				pasteboard.fileHandler.readExternalImage child.src, paste: true
				return


		$(pasteboard).trigger "noimagefound", paste: true

	focusPasteArea = () ->
		pasteArea.focus()

	self =
		isSupported: () -> "onpaste" of document
		# Initializes the module
		init: () ->
			unless @isSupported()
				$("html").addClass("no-copyandpaste")
				return

			# Clipboard fallback
			if usePasteArea
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
