#= require common
#= require lib/spin.min.js
#= require modules/moduleloader
#= require modules/analytics
#= require modules/template
#= require modules/modalwindow

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

getShortURL = () ->
	if window.location.pathname
		$.get "/images/#{window.location.pathname.replace("/", "")}/shorturl", (data) ->
			$(".short-url")
				.addClass("appear")
				.find("input").val(data.url)

pasteboard = {}
window.moduleLoader.load("analytics", pasteboard)
window.moduleLoader.load("template", pasteboard)
window.moduleLoader.load("modalWindow", pasteboard)

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
		getShortURL()
		window.drawBackgroundOverlay()

	$image.on "error", (e) ->
		$("body").addClass "broken"

	$image.attr "src", $image.data("src")

	pasteboard.analytics.init()
	pasteboard.modalWindow.init()
	$modalWindow = $ pasteboard.modalWindow

	$window.on "resize", setPosition

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

	# Confirm on image delete
	$(".delete").click (e) ->
		image =  $(this).data("image")
		pasteboard.modalWindow.show "confirm",
			content: "Are you sure you want to delete this image?",
			showConfirm: true,
			confirmText: "Yes, delete",
			showCancel: true
			cancelText: "No, cancel"

		$modalWindow.on "confirm", ->
			$modalWindow.off "confirm cancel"
			$.post "images/#{image}/delete", ->
				window.location = "/"

		$modalWindow.on "cancel", ->
			$modalWindow.off "confirm cancel"
			pasteboard.modalWindow.hide()



