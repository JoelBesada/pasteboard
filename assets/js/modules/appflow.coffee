###
# Controls the flow of the application
# (what happens when)
###
appFlow = (pasteboard) ->
	# The different states that the app goes through
	states = {
		initializing: 0
		insertingImage: 1
		takingPhoto: 2
		editingImage: 3
		uploadingImage: 4
		generatingLink: 5
	}
	$pasteboard = $(pasteboard)
	$imageEditor = null
	$modalWindow = null

	setState = (state, stateData = {}) ->
		switch state
			# State 1: Application is initializing
			when states.initializing
				pasteboard.socketConnection.init()
				pasteboard.modalWindow.init()
				pasteboard.webcam.init()
				pasteboard.extensionHandler.init()

				# The image that the user is trying to insert is too large
				$pasteboard.on "filetoolarge", (e) ->
					pasteboard.modalWindow.show("error",
						content: "The file size of the image you are trying to
								  insert exceeds the current limit of
								  #{pasteboard.fileHandler.getFileSizeLimit() / (1024 * 1024)} MB.
								  <br><br>Please try another image."
						showCancel: true
					)

				setState ++state

			# State 2: Waiting for user to insert an image
			when states.insertingImage
				# Set up drag and drop / copy and paste handlers
				pasteboard.dragAndDrop.init()
				pasteboard.copyAndPaste.init()

				# Stop the webcam stream, if any
				pasteboard.webcam.stop()

				# Show the splash screen
				$(".splash").show()
				pasteboard.webcam.showButton()

				# An image has been inserted
				$pasteboard.on "imageinserted.stateevents", (e, eventData) ->
					$pasteboard.off ".stateevents"
					$modalWindow.off "cancel"
					pasteboard.modalWindow.hide()
					setState states.editingImage, image: eventData.image

				# The user tried to insert something other than an image
				$pasteboard.on "noimagefound.stateevents", (e, eventData) ->
					content = "No image found"
					if eventData.paste
						content = "No image data was found in your clipboard,
									copy an image first (or take a screenshot)."
					else if eventData.drop
						content = "The object you dragged in is not an image file."

					pasteboard.modalWindow.show("error",
						content: content
						showCancel: true
					)

				# The user gave access to the webcam to take a photo
				$pasteboard.on "webcaminitiated.stateevents", (e, eventData) ->
					$pasteboard.off ".stateevents"
					$modalWindow.off "cancel"
					setState states.takingPhoto, eventData

				# The user tried to use the webcam without having one available
				$pasteboard.on "webcamunavailable.stateevents", (e) ->
					pasteboard.modalWindow.show "error",
						content: "You do not seem to have a webcam available (or
								  you denied the request to access it)."
						showCancel: true

				$modalWindow.on "cancel", () ->
					pasteboard.modalWindow.hide()

			# State 3: The user is using the webcam to take a picture
			when states.takingPhoto
				# Show the webcam window
				pasteboard.webcam.start()

				# Stop capturing paste and drop actions
				pasteboard.dragAndDrop.hide()
				pasteboard.copyAndPaste.hide()

				# The window is displayed
				$pasteboard.on "webcamwindowshow.stateevents", (e) ->
					# Hide things from the previous state
					$(".splash").hide()
					pasteboard.webcam.hideButton()

				$pasteboard.on "imageinserted.stateevents", (e, eventData) ->
					$pasteboard.off ".stateevents"
					$modalWindow.off "cancel"
					pasteboard.webcam.hide ->
						setState states.editingImage,
							image: eventData.image
							previousState: states.takingPhoto

				# User clicked cancel
				$pasteboard.on "cancel", (e) ->
					$pasteboard.off ".stateevents"
					# Return to the previous state
					pasteboard.webcam.hide ->
						setState states.insertingImage


			# State 4: User is looking at / editing the image
			when states.editingImage
				$(".welcome").transition(
					top: -50
					opacity: 0
				, () -> $(this).remove() )

				unless stateData.backtracked
					# Start preuploading the image right away
					pasteboard.fileHandler.preuploadFile()
					# Hide things from the previous state
					pasteboard.dragAndDrop.hide()
					pasteboard.copyAndPaste.hide()
					$(".splash").hide()
					pasteboard.webcam.hideButton()

					# Display the image editor
					pasteboard.imageEditor.init stateData.image

				# Triggered when clicking the delete button
				$imageEditor.on "cancel.stateevents", (e) ->
					$imageEditor.off ".stateevents"
					# Clear the preuploaded file
					pasteboard.fileHandler.clearFile()
					# Abort the (possibly) ongoing preupload
					pasteboard.fileHandler.abortPreupload()

					# Go back to the previous state
					pasteboard.imageEditor.hide ->
						setState stateData.previousState or states.insertingImage

				# Triggered when clicking the upload button
				$imageEditor.on "confirm.stateevents", (e) ->
					$imageEditor.off ".stateevents"
					# Upload the image
					pasteboard.imageEditor.uploadImage (upload) ->
						setState ++state, upload: upload

			# State 5: The image is uploading
			when states.uploadingImage
				progressHandler = null

				# Image upload still in progress
				if stateData.upload.inProgress
					pasteboard.modalWindow.show("upload-progress",
							showCancel: true
							showConfirm: true
							confirmText: "Upload More"
							showLink: true,
							linkText: "Go to image"
						, (modal) ->
							alreadyLoaded = pasteboard.fileHandler.getCurrentUploadLoaded()

							progressHandler = (e) ->
								# When an image is still "preuploading" (i.e. the preupload
								# didn't finish before the user clicked the upload button),
								# begin the progress indicator from 0 by subtracting the already
								# loaded bytes
								if stateData.upload.preuploading
									percent = Math.floor(((e.loaded - alreadyLoaded) / (e.total - alreadyLoaded)) * 100)
								else
									percent = Math.floor((e.loaded / e.total) * 100)

								# Update the progress bar and number with the current %
								modal.find(".progress-bar")
									.css(
										width: "#{percent}%"
									)
								.end().find(".progress-number")
									.text(if ("" + percent).length < 2 then "0#{percent}" else percent)

								onComplete() if percent is 100

							# This runs when the upload is complete but we're still waiting for
							# a response from the server
							onComplete = () ->
								modal.find(".modal-window")
										.removeClass("default")
										.addClass("generating")

								# The upload can no longer be cancelled
								$modalWindow.off "cancel"

								if stateData.upload.preuploading
									# In the case of a continued preupload we need
									# to send another request to upload the preuploaded
									# image from the server to the cloud
									stateData.upload.xhr.addEventListener "load", () ->
										pasteboard.imageEditor.uploadImage (upload) ->
											setState ++state, $.extend(upload, jQueryXHR: true, modal: modal)
								else
									setState ++state,
										xhr: stateData.upload.xhr
										modal: modal

							# The user clicked upload right between the
							# preupload completing (no more progress events will fire)
							# and the http request completing
							if pasteboard.fileHandler.getCurrentUploadRatio() is 1
								onComplete()
							else
								stateData.upload.xhr.upload.addEventListener "progress", progressHandler
						)

				# Image is already uploaded, just waiting for
				# the upload between the server and the cloud
				# to finish
				else
					pasteboard.modalWindow.show("upload-link",
						showConfirm: true
						confirmText: "Upload more"
						showLink: true,
						linkText: "Go to image"
					, (modal) ->
						setState ++state,
							xhr: stateData.upload.xhr,
							modal: modal
							preuploaded: true
					)

				# Triggered when an upload is cancelled
				$modalWindow.on "cancel.stateevents", () ->
					$modalWindow.off ".stateevents"
					# Only cancel the upload if it's not a preupload, else let it keep running in the background
					stateData.upload.xhr.abort() if stateData.upload.xhr and not stateData.upload.preuploading
					stateData.upload.xhr.upload.removeEventListener "progress", progressHandler

					# Backtrack to the image editing state
					pasteboard.modalWindow.hide()
					setState states.editingImage, backtracked: true

			# State 6: The image link is being generated
			when states.generatingLink
				$pasteboard.trigger "imageuploaded"
				# Image was already preuploaded when the upload
				# button was pressed
				if stateData.preuploaded
					stateData.xhr.success (data) ->
						stateData.modal.find(".modal-window")
							.removeClass("default generating")
							.addClass("done")

						stateData.modal
							.find(".image-link")
								.val(data.url)
								.end()
							.find(".link.button")
								.attr("href", data.url)


				else
					# Some animations to transition from displaying
					# the upload bar to showing the image link
					showLink = (url) ->
						stateData.modal.find(".modal-window")
							.removeClass("generating")
							.addClass("done")

						setTimeout(() ->
							stateData.modal.find(".upload-bar")
								.hide()
							.end().find(".image-link")
								.show()
								.addClass("appear")

							stateData.modal.find(".cancel").transition(
								opacity: 0
							, 500, () ->
								$(this).css "display", "none"
								stateData.modal.find(".confirm, .link.button")
									.css("display", "inline-block")
									.transition({
										opacity: 1
									}, 500)
							)

							setTimeout(() ->
								stateData.modal
									.find(".image-link")
										.val(url)
										.end()
									.find(".link.button")
										.attr("href", url)
							, 500)
						, 500)

					if stateData.jQueryXHR
						stateData.xhr.success (data) ->
							showLink data.url
					else
						stateData.xhr.addEventListener "load", (e) ->
							json = {}
							try
								json = JSON.parse e.target.response
							catch e
								log e.target.response
							showLink(if json.url then json.url else "Something went wrong")

				# Go back to uploading another image
				$modalWindow.on "confirm.stateevents", () ->
					$modalWindow.off ".stateevents"
					pasteboard.modalWindow.hide()
					pasteboard.imageEditor.hide () -> setState states.insertingImage, backtracked: true

	self =
		# Starts the application flow
		start: () ->
			$imageEditor = $(pasteboard.imageEditor)
			$modalWindow = $(pasteboard.modalWindow)
			setState(0)

window.moduleLoader.addModule "appFlow", appFlow
