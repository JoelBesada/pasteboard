#= require_tree lib
#= require pasteboard
#= require_tree .


(($) ->

	$ ->
	 	# used to prevent transition "flashing" with -prefix-free
		$("body").addClass "loaded"

		pasteBoard.dragAndDrop.init()
		pasteBoard.copyAndPaste.init()

)(jQuery)

