
### 
#	Image editor module, the image viewing / editing interface.
###

(($) ->

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
		imagePosition = 
			x: 0
			y: 0
		
		$imageEditor = null
		$imageContainer = null
		$image = null
		$xScrollBar = null
		$yScrollBar = null
		$xScrollTrack = null
		$yScrollTrack = null
		$xScrollHandle = null
		$yScrollHandle = null
		$uploadButton = null
		$window = $(window)
		
		# Add all the event listeners			
		addEvents = () ->
			$window.on "resize", () -> 
				setPosition()
				setSize()
				scrollImage 0, 0

			$(document)
				.on("click", ".upload-button", uploadImage)
				.on("click", ".delete-button", hide)
				.on("mousewheel", ".image-container", scrollWheelHandler)
				.on("mousedown", ".image-editor .y-scroll-bar, .image-editor .x-scroll-bar", mouseScrollHandler)
				.on("mouseup", () -> 
					isDragging = false
				)
				.on("mousemove", (e) -> 
					dragScrollHandler e if isDragging 
				)

		# Cache the needed jQuery element objects for quicker access
		# TODO: Organize this better
		cacheElements = (element) ->
			$imageEditor = $(element)
			$imageContainer = $imageEditor.find(".image-container")
			$image = $imageContainer.find(".image")
			$xScrollBar = $imageEditor.find(".x-scroll-bar")
			$yScrollBar = $imageEditor.find(".y-scroll-bar")
			$xScrollTrack = $xScrollBar.find(".track")
			$yScrollTrack = $yScrollBar.find(".track")
			$xScrollHandle = $xScrollTrack.find(".handle")
			$yScrollHandle = $yScrollTrack.find(".handle")
			$uploadButton = $imageEditor.find(".upload-button")

		# Sets the vertical position of the image editor window
		setPosition = () ->
			y = $window.height() / 2 - $imageEditor.outerHeight() / 2
			y = 0 if $imageEditor.outerHeight() > $window.height()
			$imageEditor.css(
				"top": y
			)

		# Resizes the image editor window, adds scrollbars if needed
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

			# TODO: Make this less repetitive
			if $imageContainer.width() < image.width
				scrollableX = true
				$imageEditor.addClass("scroll-x")
				$imageContainer.css("height", height - $xScrollBar.outerHeight())

				# Make the scroll handle represent the visible image width
				# relative to the track
				$xScrollHandle
					.css("width", ($imageContainer.width() / image.width) * $xScrollTrack.width())
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
				$yScrollHandle
					.css("height", ($imageContainer.height() / image.height) * $yScrollTrack.height())
			else 
				$imageEditor.removeClass("scroll-y")
				$imageContainer.css("width", "")
				scrollableY = false
				
		# Handles mouse scrolling (clicking and dragging)
		mouseScrollHandler = (e) ->
			return if e.button is not 0
			$target = $(e.currentTarget)

			# TODO: Make this less repetitive
			if $target.hasClass("y-scroll-bar")
				if $yScrollHandle.offset().top <= e.clientY <= $yScrollHandle.offset().top + $yScrollHandle.height()
					dragDirection = "y"
					dragOffsetY = e.clientY - $yScrollHandle.offset().top
					isDragging = true
				else
					# Ignore clicks on the padding
					return if e.clientY > $yScrollBar.offset().top + $yScrollBar.height()
					if e.clientY < $yScrollHandle.offset().top
						scrollImage(0, SCROLL_SPEED)
					else
						scrollImage(0, -SCROLL_SPEED)

			else if $target.hasClass("x-scroll-bar")
				if $xScrollHandle.offset().left <= e.clientX <= $xScrollHandle.offset().left + $xScrollHandle.width()
					dragDirection = "x"
					dragOffsetX = e.clientX - $xScrollHandle.offset().left
					isDragging = true
				else
					# Ignore clicks on the padding
					return if e.clientX > $xScrollBar.offset().left + $xScrollBar.width()
					if e.clientX < $xScrollHandle.offset().left
						scrollImage(SCROLL_SPEED, 0)
					else
						scrollImage(-SCROLL_SPEED, 0)

			e.preventDefault()
			return false

		# Handles mouse wheel scrolling.
		# (Scrolling while holding shift scrolls the image sideways)
		scrollWheelHandler = (e) ->
			return unless scrollableY or ((e.originalEvent.shiftKey or e.originalEvent.wheelDeltaX) and scrollableX)
			direction = if e.originalEvent.wheelDelta < 0 then -1 else 1
			if e.originalEvent.shiftKey or e.originalEvent.wheelDeltaX
				scrollImage(direction * SCROLL_SPEED, 0) if scrollableX
			else
				scrollImage(0, direction * SCROLL_SPEED) if scrollableY

		# Handles dragging of the scroll bar handles
		dragScrollHandler = (e) ->
			if dragDirection is "x"
				x = ((e.clientX - dragOffsetX - $xScrollTrack.offset().left) / $xScrollTrack.width()) * image.width
				scrollImageTo(x, undefined)	
			else if dragDirection is "y"
				y = ((e.clientY - dragOffsetY - $yScrollTrack.offset().top) / $yScrollTrack.height()) * image.height
				scrollImageTo(undefined, y)				

		# Scrolls the image by the given number of pixels
		scrollImage = (x, y) ->
			newX = -(imagePosition.x + x)
			newY = -(imagePosition.y + y)

			scrollImageTo(newX, newY)

		# Scrolls the image to the given coordinates
		scrollImageTo = (x, y) ->
			x = -imagePosition.x if x is undefined
			y = -imagePosition.y if y is undefined

			# Cap values
			x = Math.max 0, Math.min x, $image.width() - $imageContainer.width()
			y = Math.max 0, Math.min y, $image.height() - $imageContainer.height()

			$image.css(
					x: -x + "px"
					y: -y + "px"
				)

			imagePosition.x = -x
			imagePosition.y = -y

			# Set the handle positions
			$yScrollHandle
				.css("top", (y / ($image.height() - $imageContainer.height())) * ($yScrollTrack.height() - $yScrollHandle.height() )  + "px")

			$xScrollHandle
				.css("left", (x / ($image.width() - $imageContainer.width())) * ($xScrollTrack.width() - $xScrollHandle.width() )  + "px")

		# Loads an image and sets up the editor
		loadImage = (img) ->
			image = new Image()
			image.src = img
			image.onload = () ->
				pasteBoard.template.compile(
					"jstemplates/imageeditor.tmpl",
					{ url: img },
					(compiledTemplate) ->
						cacheElements(compiledTemplate) 
						
						$imageEditor.appendTo("body")
						$image.css(
							"width": image.width
							"height": image.height
						)

						setSize()
						setPosition()
				)

		# Uploads the image
		uploadImage = () ->
			pasteBoard.fileHandler.uploadFile image.src
			
			# Prevent multiple uploads
			$uploadButton.off "click"

		# TODO: Clean up event listeners
		hide = () ->
			$(".splash").show()
			pasteBoard.dragAndDrop.init()
			pasteBoard.copyAndPaste.init()
			$imageEditor.remove()

		self = 
			# Initializes the image editor.
			# Loads and displays the given image
			init: (img, type) ->
				fileType ||= type
				
				# Start loading the template
				pasteBoard.template.load(TEMPLATE_URL)
				loadImage img

				pasteBoard.dragAndDrop.hide()
				pasteBoard.copyAndPaste.hide()
				$(".splash").hide()
				
				if firstInit
					addEvents()
					firstInit = false
				
	)() 
)(jQuery)