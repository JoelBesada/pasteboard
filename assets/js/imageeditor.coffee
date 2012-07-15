(($) ->
	PasteBoard.ImageEditor = (() ->
		self = 
			init: (img) ->
				image = new Image()
				image.src = img

				image.onload = () ->
					PasteBoard.DragAndDrop.hide()
					$(".splash").hide()
					$("body").append image


	)() 
)(jQuery)
