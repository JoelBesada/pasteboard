(($) ->
	PasteBoard.ImageEditor = (() ->
		MAX_WIDTH_RATIO = 0.8
		MAX_HEIGHT_RATIO = 0.8

		$window = $(window)
		image = null
		$imageEditor = $("<div>")
							.addClass("image-editor")

		$uploadButton = $("<button>")
							.addClass("button upload-button")
							.text("Upload")

		setPosition = () ->
			y = $window.height() / 2 - $imageEditor.outerHeight() / 2
			y = 0 if $imageEditor.outerHeight() > $window.height()
			$imageEditor.css(
				"top": y
			)

		setSize = () ->
			width = $(image).width()
			height = $(image).height()
			maxWidth = MAX_WIDTH_RATIO * $window.width()
			maxHeight = MAX_HEIGHT_RATIO * $window.height()


			width = Math.min maxWidth, width
			height = Math.min maxHeight, height

			log height

			$imageEditor
				.css(
					"width": width
					"height": height
					"overflow-x": if width is maxWidth then "scroll" else "hidden"
					"overflow-y": if height is maxHeight then "scroll" else "hidden"
				)

		
		self = 
			init: (img) ->
				this.loadImage img
				PasteBoard.DragAndDrop.hide()
				$(".splash").hide()
				$window.on "resize", () -> 
					setPosition()
					setSize()

				
			loadImage: (img) ->
				image = new Image()
				image.src = img

				image.onload = () ->
					$imageEditor
						.append(image)
						.appendTo("body")

					setSize()
					setPosition()

					$uploadButton
						.appendTo("body")

	)() 
)(jQuery)
