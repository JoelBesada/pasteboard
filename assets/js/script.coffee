#= require_tree lib
#= require pasteboard
#= require_tree .


(($) ->

	$ ->
	 	# used to prevent transition "flashing" with -prefix-free
		$("body").addClass "loaded"

		PasteBoard.DragAndDrop.init()
		PasteBoard.CopyAndPaste.init()

)(jQuery)

