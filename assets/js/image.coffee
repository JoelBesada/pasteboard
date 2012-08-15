#= require common

$window = $(window)
$imageContainer = null
$image = null
fullScreen = false
setSize = () ->
	width = $(window).outerWidth()
	height = Math.min($(window).outerHeight(), ($image.outerHeight() + 65))

	$imageContainer.css
		width: width
		height: height

setPosition = () ->
	if $imageContainer.outerHeight() < $window.outerHeight()
		$imageContainer.css
			top: $window.outerHeight() / 2 - $imageContainer.outerHeight() / 2
	else
		$imageContainer.css
			top: ""

$ () ->
	$imageContainer = $(".image-container")	
	$image = $imageContainer.find(".image")

	if $image.height() is 0
		# Periodically check the height until
		# it has been set
		interval = setInterval(() ->
			if $image.height() > 0
				clearInterval interval
				setPosition()
		, 250)
	else
		setPosition()
	
	$window.on "resize", setPosition
	
	$image.on "click", () ->
		fullScreen = !fullScreen
		$("body").toggleClass("full-screen")

		if fullScreen
			setSize()
			$window.on "resize", setSize
		else
			$window.off "resize", setSize
			$imageContainer.css
				width: ""
				height: ""
		
		setPosition()


