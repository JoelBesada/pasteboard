###
# Tracks events with Google Analytics
###
analytics = (pasteboard) ->
	page = ""
	$document = null
	$pasteboard = $(pasteboard)
	loggedErrors = {}

	track = (category, action, label, value) ->
		eventArray = ['_trackEvent', "#{page} - #{category}", action]
		eventArray.push label if label
		eventArray.push parseInt(value, 10) if value
		_gaq.push eventArray

	trackOutboundLinks = () ->
		$document.on "click", "a[data-track]", (e) ->
			$this = $(this)
			track "Outbound Link", "Click", $this.data("track")
			unless $this.attr("target") is "__blank" or e.ctrlKey or e.metaKey
				e.preventDefault()
				# Give Google Analytics some time to track the event
				# (probably not the best way to do this)
				setTimeout(() ->
					window.location = $this.attr("href")
				, 150)

	trackInsertedImages = () ->
		$pasteboard.on
			"filetoolarge": (e, eventData) ->
				kB = eventData.size / 1024
				track "Image Inserted", actionString(eventData.action), "Too Large", kB
			"imageinserted": (e, eventData) ->
				kB = eventData.size / 1024
				track "Image Inserted", actionString(eventData.action), "Successfully", kB

	trackErrors = () ->
		$(window).on "error", (e) ->
			# Prevent logging the same error multiple times
			unless loggedErrors[e.originalEvent.message]
				loggedErrors[e.originalEvent.message] = true
				track "Error", e.originalEvent.message, "#{e.originalEvent.filename} :#{e.originalEvent.lineno}"

	actionString = (action) ->
		return "Copy and Paste" if action.paste
		return "Drag and Drop" if action.drop
		return "Webcam" if action.webcam
		return "Unknown Action"

	self =
		init: () ->
			return unless window._gaq
			$document = $(document)
			page = $("body").data("page")

			trackOutboundLinks()
			trackInsertedImages()
			trackErrors()

window.moduleLoader.addModule "analytics", analytics
