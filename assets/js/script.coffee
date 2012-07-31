#= require_tree lib
#= require pasteboard
#= require_tree .


(($) ->
	$window = $(window)

	drawBackgroundOverlay = () ->
		$canvas = $(".shadow")
		ctx = $canvas[0].getContext("2d")
		return unless ctx

		$canvas.width $window.width()
		$canvas.height $window.height()

		ctx.clearRect 0, 0, $window.width(), $window.height()

		gradient = ctx.createRadialGradient(150, 50, 0, 150, 50, 200)
		gradient.addColorStop 0, "rgba(0,0,0,0)"
		gradient.addColorStop 0.3, "rgba(0,0,0,0.1)"
		gradient.addColorStop 0.6, "rgba(0,0,0,0.25)"
		gradient.addColorStop 1, "rgba(0,0,0,0.6)"

		ctx.fillStyle = gradient
		ctx.fillRect 0, 0, $window.width(), $window.height()
		
	
	$ ->
	 	# used to prevent transition "flashing" with -prefix-free
		$("body").addClass "loaded"

		pasteBoard.dragAndDrop.init()
		pasteBoard.copyAndPaste.init()

		drawBackgroundOverlay()
		$window.resize drawBackgroundOverlay


)(jQuery)

