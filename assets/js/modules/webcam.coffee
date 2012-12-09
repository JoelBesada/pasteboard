##
# Webcam module, allows the user to take
# pictures with their webcam
##

webcam = (pasteboard) ->
	TEMPLATE_URL = "jstemplates/webcamwindow.tmpl"

	video = null
	stream = null

	$webcamWindow = null
	$cancelButton = null
	$confirmButton = null
	$pasteboard = $(pasteboard)

	# Unprefix methods
	navigator.getUserMedia = navigator.getUserMedia or navigator.webkitGetUserMedia or
    navigator.mozGetUserMedia or navigator.msGetUserMedia
	window.URL = window.URL or window.webkitURL

	# Request access to the webcam
	#
	# CURRENT DRAWBACK:
	# There doesn't seem to be a way to check if the user
	# actually has a webcam before requesting access to one,
	# would be nice to know so that the 'Use webcam' button
	# could be hidden
	requestWebcam = () ->
		navigator.getUserMedia
			video: true
			audio: false
		, (localMediaStream) ->
			stream = localMediaStream
			$pasteboard.trigger "webcaminitiated"
		, (error) ->
		    $pasteboard.trigger "webcamunavailable"

	# Stream the video from the webcam to the video element
	streamVideo = ->
		if video.mozSrcObject is null
	        video.mozSrcObject = stream
      	else if window.URL
	        video.src = window.URL.createObjectURL stream
	    else
	    	video.src = stream

	    video.play()

	    $(video).on "canplay", (e) ->
	    	displayWindow()
	    	video.play() # Firefox stupidness, play the video again
	    	$(video).off "canplay"

	# Display the webcam window
	displayWindow = ->
		$pasteboard.trigger "webcamwindowshow", webcamWindow: $webcamWindow
		$("body").append $webcamWindow
		setPosition()
		$(window).on "resize", setPosition

		$cancelButton.on "click", -> $pasteboard.trigger "cancel"
		$confirmButton.on "click", -> pasteboard.fileHandler.readVideo video

	# Center the window
	setPosition = ->
		$webcamWindow.css
			top: $(window).outerHeight() / 2 - $webcamWindow.outerHeight() / 2 - 50
			left: $(window).outerWidth() / 2 - $webcamWindow.outerWidth() / 2

	self =
		isSupported: -> !!navigator.getUserMedia and window.dataURLtoBlob
		showButton: ->
			return unless @isSupported()
			$(".webcam-button")
				.show()
				.css("opacity", 0)
				.transition(
					opacity: 1
				, 500)
		hideButton: -> $(".webcam-button").hide()

		hide: (callback) ->
			$webcamWindow.transition(
				opacity: 0
				scale: 0.95
			, 500, () ->
				$webcamWindow.remove()
				callback?()
			)

		# Stop the stream (turns off the webcam)
		stop: -> stream?.stop?()

		# Start streaming the webcam video and display the window
		start: ->
			pasteboard.template.compile(
				TEMPLATE_URL,
				{},
				(compiledTemplate) ->
					$webcamWindow = $(compiledTemplate)
					$cancelButton = $webcamWindow.find ".cancel"
					$confirmButton = $webcamWindow.find ".confirm"

					video = $webcamWindow.find("video")[0]
					streamVideo()
			)
		init: ->
			return unless @isSupported()
			pasteboard.template.load(TEMPLATE_URL)
			$(".webcam-button").click requestWebcam


window.moduleLoader.addModule "webcam", webcam
