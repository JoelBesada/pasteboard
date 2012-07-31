(($) ->
	# TODO:
	# 	upload button in template

	pasteBoard.imageEditor = (() ->
		MAX_WIDTH_RATIO = 0.8
		MAX_HEIGHT_RATIO = 0.8
		SCROLL_SPEED = 50
		TEMPLATE_URL = "jstemplates/imageeditor.tmpl"

		firstInit = true
		image = null
		fileType = null
		scrollableX = false
		scrollableY = false
		isDragging = false
		dragDirection = null
		dragOffsetX = 0
		dragOffsetY = 0
		
		$imageEditor = null
		$imageContainer = null
		$xScrollBar = null
		$yScrollBar = null
		$uploadButton = null
		$window = $(window)
							
		addEvents = () ->
			$window.on "resize", () -> 
				setPosition()
				setSize()
				scrollImage 0, 0

			$(document)
				.on("click", ".upload-button", uploadImage)
				.on("click", ".delete-button", hide)
				.on("mousewheel", ".image-container", scrollWheelHandler)
				.on("mousedown", ".image-editor .y-scroll-bar, .image-editor .x-scroll-bar", (e) -> 
					return if e.button is not 0
					e.preventDefault()
					return false
				)
				.on("mousedown", ".image-editor .y-scroll-bar", (e) -> 
					$handle = $(this).find(".handle")
					if $handle.offset().top <= e.clientY <= $handle.offset().top + $handle.height()
						dragDirection = "y"
						dragOffsetY = e.clientY - $handle.offset().top
						isDragging = true
					else
						# Ignore clicks on the padding
						return if e.clientY > $yScrollBar.offset().top + $yScrollBar.height()
						if e.clientY < $handle.offset().top
							scrollImage(0, SCROLL_SPEED)
						else
							scrollImage(0, -SCROLL_SPEED)
				)
				.on("mousedown", ".image-editor .x-scroll-bar", (e) -> 
					$handle = $(this).find(".handle")
					if $handle.offset().left <= e.clientX <= $handle.offset().left + $handle.width()
						dragDirection = "x"
						dragOffsetX = e.clientX - $handle.offset().left
						isDragging = true
					else
						# Ignore clicks on the padding
						return if e.clientX > $xScrollBar.offset().left + $xScrollBar.width()
						if e.clientX < $handle.offset().left
							scrollImage(SCROLL_SPEED, 0)
						else
							scrollImage(-SCROLL_SPEED, 0)
				)
				.on("mouseup", () -> 
					isDragging = false
				)
				.on("mousemove", (e) -> 
					dragScrollHandler e if isDragging 
				)

		setPosition = () ->
			y = $window.height() / 2 - $imageEditor.outerHeight() / 2
			y = 0 if $imageEditor.outerHeight() > $window.height()
			$imageEditor.css(
				"top": y
			)

		setSize = () ->
			maxWidth = MAX_WIDTH_RATIO * $window.width()
			maxHeight = MAX_HEIGHT_RATIO * $window.height()

			width = Math.min maxWidth, image.width
			height = Math.min maxHeight, image.height

			
			$imageEditor
				.css(
					"width": width
					"height": height
				)

			if $imageContainer.width() < image.width
				scrollableX = true
				$imageEditor.addClass("scroll-x")
				$imageContainer.css("height", height - $xScrollBar.outerHeight())

				# Make the scroll handle represent the visible image width
				# relative to the track
				$xScrollBar.find(".handle")
					.css("width", ($imageContainer.width() / image.width) * $xScrollBar.find(".track").width())
			else 
				$imageEditor.removeClass("scroll-x")
				$imageContainer.css("height", "")
				scrollableX = false
			
			if $imageContainer.height() < image.height
				scrollableY = true
				$imageEditor.addClass("scroll-y")
				$imageContainer.css("width", width - $yScrollBar.outerWidth())

				# Make the scroll handle represent the visible image height
				# relative to the track
				$yScrollBar.find(".handle")
					.css("height", ($imageContainer.height() / image.height) * $yScrollBar.find(".track").height())
			else 
				$imageEditor.removeClass("scroll-y")
				$imageContainer.css("width", "")
				scrollableY = false
				

		scrollWheelHandler = (e) ->
			return unless scrollableY or ((e.originalEvent.shiftKey or e.originalEvent.wheelDeltaX) and scrollableX)
			direction = if e.originalEvent.wheelDelta < 0 then -1 else 1
			if e.originalEvent.shiftKey or e.originalEvent.wheelDeltaX
				scrollImage(direction * SCROLL_SPEED, 0) if scrollableX
			else
				scrollImage(0, direction * SCROLL_SPEED) if scrollableY

		dragScrollHandler = (e) ->
			if dragDirection is "x"
				$track = $xScrollBar.find(".track")
				x = ((e.clientX - dragOffsetX - $track.offset().left) / $track.width()) * image.width
				scrollImageTo(x, undefined)	
			else if dragDirection is "y"
				$track = $yScrollBar.find(".track")
				y = ((e.clientY - dragOffsetY - $track.offset().top) / $track.height()) * image.height
				scrollImageTo(undefined, y)				


		scrollImage = (x, y) ->
			$image = $imageEditor.find(".image")
      		
			newX = -((parseInt($image.css("left"), 10) or 0)  + x)
			newY = -((parseInt($image.css("top"), 10) or 0)  + y)

			scrollImageTo(newX, newY)

		scrollImageTo = (x, y) ->
			$image = $imageEditor.find(".image")
			
			x = -parseInt($image.css("left"), 10) if x is undefined
			y = -parseInt($image.css("top"), 10) if y is undefined

			# Cap values
			x = Math.max 0, Math.min x, $image.width() - $imageContainer.width()
			y = Math.max 0, Math.min y, $image.height() - $imageContainer.height()

			$image.css(
					left: -x + "px"
					top: -y + "px"
				)
			$yScrollBar.find(".handle")
				.css("top", (y / ($image.height() - $imageContainer.height())) * ($yScrollBar.find(".track").height() - $yScrollBar.find(".handle").height() )  + "px")

			$xScrollBar.find(".handle")
				.css("left", (x / ($image.width() - $imageContainer.width())) * ($xScrollBar.find(".track").width() - $xScrollBar.find(".handle").width() )  + "px")

		uploadImage = () ->
			canvas = document.createElement("canvas")
			context = canvas.getContext("2d")

			canvas.width = image.width
			canvas.height = image.height

			context.drawImage image, 0, 0
			dataURL = if fileType then canvas.toDataURL(fileType) else canvas.toDataURL()
			pasteBoard.fileHandler.uploadFile dataURL
			$uploadButton.off "click"

		hide = () ->
			$(".splash").show()
			pasteBoard.dragAndDrop.init()
			pasteBoard.copyAndPaste.init()
			$imageEditor.remove()

		self = 
			init: (img, type) ->
				fileType ||= type
				
				pasteBoard.template.load(TEMPLATE_URL)
				this.loadImage img

				pasteBoard.dragAndDrop.hide()
				pasteBoard.copyAndPaste.hide()
				$(".splash").hide()
				
				if firstInit
					addEvents()
					firstInit = false
				
				
			loadImage: (img) ->
				image = new Image()
				image.src = img
				image.onload = () ->
					pasteBoard.template.compile(
						"jstemplates/imageeditor.tmpl",
						{ url: img },
						(compiledTemplate) -> 
							$imageEditor = $(compiledTemplate)
							$imageContainer = $imageEditor.find(".image-container")
							$xScrollBar = $imageEditor.find(".x-scroll-bar")
							$yScrollBar = $imageEditor.find(".y-scroll-bar")
							$uploadButton = $imageEditor.find(".upload-button")


							$imageEditor.appendTo("body")
							$imageEditor.find(".image")
								.css(
									"width": image.width
									"height": image.height
								)

							setSize()
							setPosition()
					)
		
	)() 
)(jQuery)