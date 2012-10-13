#= require common
#= require lib/spin.min.js
#= require modules/moduleloader
#= require modules/analytics

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

pasteboard = {}
window.moduleLoader.load("analytics", pasteboard)

$ () ->
	$imageContainer = $(".image-container")	
	$image = $imageContainer.find(".image")
	
	spinner = new Spinner(
		color: "#eee"
		lines: 12
		length: 5
		width: 3
		radius: 6
		hwaccel: true
		className: "spin"
	).spin($(".spinner")[0]);

	$image.on "load", (e) ->
		spinner.stop()
		setPosition()
		$image.addClass("appear")
		window.drawBackgroundOverlay()

	pasteboard.analytics.init()

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
		$(window).scrollTop(0)

		if fullScreen
			setSize()
			$window.on "resize", setSize
		else
			$window.off "resize", setSize
			$imageContainer.css
				width: ""
				height: ""
		
		setPosition()
