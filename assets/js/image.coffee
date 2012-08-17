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
				$image.addClass("appear")
				window.drawBackgroundOverlay()
		, 250)
	else
		setPosition()
		$image.addClass("appear")
	
	$window.on "resize", setPosition
	
	# Fetch the shortlink
	if window.location.pathname
		$.get "/shorturl/" + window.location.pathname.replace("/", ""), (data) ->
			$(".short-url")
				.addClass("appear")
				.find("input").val(data.url)

	# Toggle between fullscreen and regular view
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

	# Analytics
	if window._gaq
		$(".author a").on "click", () ->
			_gaq.push ['_trackEvent', 'image page', 'click', 'twitter link']


