### 
#	Image editor module, the image viewing / editing interface.
###
imageEditor = (pasteboard) ->
	MAX_WIDTH_RATIO = 0.8
	MAX_HEIGHT_RATIO = 0.8
	SCROLL_SPEED = 50
	TEMPLATE_URL = "jstemplates/imageeditor.tmpl"

	image = null
	fileType = null
	isDragging = false
	dragDirection = null

	scrollable =
		x: false
		y: false
	dragOffset =
		x: 0
		y: 0
	imagePosition = 
		x: 0
		y: 0
	
	$imageEditor = null
	$imageContainer = null
	$image = null
	$scrollBar = 
		x:
			bar: null
			track: null
			handle: null
		y:
			bar: null
			track: null
			handle: null	
	
	$uploadButton = null
	$window = $(window)
	$document = $(document)

	# Add all the event listeners			
	addEvents = () ->
		$window.on "resize.imageeditorevent", () -> 
			setPosition()
			setSize()
			scrollImage 0, 0

		$document
			.on("click.imageeditorevent", ".upload-button", uploadImage)
			.on("click.imageeditorevent", ".delete-button", hide)
			.on("mousewheel.imageeditorevent", ".image-container", scrollWheelHandler)
			.on("mousedown.imageeditorevent", ".image-editor .y-scroll-bar, .image-editor .x-scroll-bar", mouseScrollHandler)
			.on("mouseup.imageeditorevent", () -> 
				isDragging = false
			)
			.on("mousemove.imageeditorevent", (e) -> 
				dragScrollHandler e if isDragging 
			)
	removeEvents = () ->
		$document.off(".imageeditorevent")
		$window.off(".imageeditorevent")

	# Cache the needed jQuery element objects for quicker access
	cacheElements = (element) ->
		$imageEditor = $(element)
		$imageContainer = $imageEditor.find(".image-container")
		$image = $imageContainer.find(".image")
		for coordinate of $scrollBar
			$scrollBar[coordinate].bar = $imageEditor.find(".#{coordinate}-scroll-bar");
			$scrollBar[coordinate].track = $scrollBar[coordinate].bar.find(".track");
			$scrollBar[coordinate].handle = $scrollBar[coordinate].track.find(".handle");

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
			scrollable.x = true
			$imageEditor.addClass("scroll-x")
			$imageContainer.css("height", height - $scrollBar.x.bar.outerHeight())

			# Make the scroll handle represent the visible image width
			# relative to the track
			$scrollBar.x.handle
				.css("width", ($imageContainer.width() / image.width) * $scrollBar.x.track.width())
		else 
			$imageEditor.removeClass("scroll-x")
			$imageContainer.css("height", "")
			scrollable.x = false
		
		if $imageContainer.height() < image.height
			scrollable.y = true
			$imageEditor.addClass("scroll-y")
			$imageContainer.css("width", width - $scrollBar.y.bar.outerWidth())

			# Make the scroll handle represent the visible image height
			# relative to the track
			$scrollBar.y.handle
				.css("height", ($imageContainer.height() / image.height) * $scrollBar.y.track.height())
		else 
			$imageEditor.removeClass("scroll-y")
			$imageContainer.css("width", "")
			scrollable.y = false
			
	# Handles mouse scrolling (clicking and dragging)
	mouseScrollHandler = (e) ->
		return if e.button is not 0
		$target = $(e.currentTarget)

		# TODO: Make this less repetitive
		if $target.hasClass("y-scroll-bar")
			if $scrollBar.y.handle.offset().top <= e.clientY <= $scrollBar.y.handle.offset().top + $scrollBar.y.handle.height()
				dragDirection = "y"
				dragOffset.y = e.clientY - $scrollBar.y.handle.offset().top
				isDragging = true
			else
				# Ignore clicks on the padding
				return if e.clientY > $scrollBar.y.bar.offset().top + $scrollBar.y.bar.height()
				if e.clientY < $scrollBar.y.handle.offset().top
					scrollImage(0, SCROLL_SPEED)
				else
					scrollImage(0, -SCROLL_SPEED)

		else if $target.hasClass("x-scroll-bar")
			if $scrollBar.x.handle.offset().left <= e.clientX <= $scrollBar.x.handle.offset().left + $scrollBar.x.handle.width()
				dragDirection = "x"
				dragOffset.x = e.clientX - $scrollBar.x.handle.offset().left
				isDragging = true
			else
				# Ignore clicks on the padding
				return if e.clientX > $scrollBar.x.bar.offset().left + $scrollBar.x.bar.width()
				if e.clientX < $scrollBar.x.handle.offset().left
					scrollImage(SCROLL_SPEED, 0)
				else
					scrollImage(-SCROLL_SPEED, 0)

		e.preventDefault()
		return false

	# Handles mouse wheel scrolling.
	# (Scrolling while holding shift scrolls the image sideways)
	scrollWheelHandler = (e) ->
		deltaX = e.originalEvent.wheelDeltaX or 0
		deltaY = e.originalEvent.wheelDeltaY or e.originalEvent.wheelDelta or 0

		if e.originalEvent.shiftKey
			deltaX ||= deltaY
			deltaY = 0

		scrollImage deltaX / 2, deltaY / 2

	# Handles dragging of the scroll bar handles
	dragScrollHandler = (e) ->
		if dragDirection is "x"
			x = ((e.clientX - dragOffset.x - $scrollBar.x.track.offset().left) / $scrollBar.x.track.width()) * image.width
			scrollImageTo(x, undefined)	
		else if dragDirection is "y"
			y = ((e.clientY - dragOffset.y - $scrollBar.y.track.offset().top) / $scrollBar.y.track.height()) * image.height
			scrollImageTo(undefined, y)				

	# Scrolls the image by the given number of pixels
	scrollImage = (x, y) ->
		x = 0 unless scrollable.x
		y = 0 unless scrollable.y
		
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

		# Round values
		x = Math.round x
		y = Math.round y

		$image.css(
			x: -x + "px"
			y: -y + "px"
		)

		imagePosition.x = -x
		imagePosition.y = -y

		# Set the handle positions
		$scrollBar.y.handle
			.css("y", Math.round((y / ($image.height() - $imageContainer.height())) * ($scrollBar.y.track.height() - $scrollBar.y.handle.height() ))  + "px")

		$scrollBar.x.handle
			.css("x", Math.round((x / ($image.width() - $imageContainer.width())) * ($scrollBar.x.track.width() - $scrollBar.x.handle.width() ))  + "px")

	# Loads an image and sets up the editor
	loadImage = (img) ->
		pasteboard.fileHandler.preuploadFile img

		image = new Image()
		image.src = img
		image.onload = () ->
			pasteboard.template.compile(
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
		pasteboard.fileHandler.uploadFile image.src
		# Prevent multiple uploads
		$document.off("click", ".upload-button", uploadImage)

	hide = () ->
		$.post("/clearfile", 
			id: pasteboard.socketConnection.getID()
		);
		pasteboard.fileHandler.abortPreupload()
		$(".splash").show()
		$imageEditor.transition(
			opacity: 0
			scale: 0.95
		, () ->
			pasteboard.dragAndDrop.init()
			pasteboard.copyAndPaste.init()
			$imageEditor.remove()
		)

		removeEvents()

	self = 
		# Initializes the image editor.
		# Loads and displays the given image
		init: (img, type) ->
			fileType ||= type
			
			# Start loading the template
			pasteboard.template.load(TEMPLATE_URL)
			loadImage img

			# Reset values
			isDragging = false
			scrollable.x = false
			scrollable.y = false
			dragOffset.x = 0
			dragOffset.y = 0
			imagePosition.x = 0
			imagePosition.y = 0

			pasteboard.dragAndDrop.hide()
			pasteboard.copyAndPaste.hide()
			$(".splash").hide()

			addEvents()

			
window.moduleLoader.addModule "imageEditor", imageEditor
