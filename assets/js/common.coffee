#= require lib/jquery.min.js

$window = $(window)
$body = $("body")
$canvas = null

# Global console.log shorthand
window.log = ->
	if window.console
		window.console.log.apply window.console, arguments

# Draws a canvas overlay for the vignette effect
# TODO: Use a CSS gradient instead?
window.drawBackgroundOverlay = () ->
	$canvas ||= $(".shadow")
	return unless $canvas[0].getContext
	
	ctx = $canvas[0].getContext("2d")

	$canvas.css(
		"width": Math.max $body.outerWidth(), $window.width()
		"height": Math.max $body.outerHeight(), $window.height()
	)
	ctx.clearRect 0, 0, $window.width(), $window.height()

	gradient = ctx.createRadialGradient(150, 50, 0, 150, 50, 200)
	gradient.addColorStop 0, "rgba(0,0,0,0)"
	gradient.addColorStop 0.3, "rgba(0,0,0,0.1)"
	gradient.addColorStop 0.6, "rgba(0,0,0,0.25)"
	gradient.addColorStop 1, "rgba(0,0,0,0.6)"

	ctx.fillStyle = gradient
	ctx.fillRect 0, 0, $window.width(), $window.height()

$ () ->
 	# Used to prevent transition "flashing" on load with -prefix-free
	$("body").addClass "loaded"

	drawBackgroundOverlay()
	$window.resize drawBackgroundOverlay
