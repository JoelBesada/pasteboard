### 
# Controls the flow of the application
# (what happens when) 
###
appFlow = (pasteboard) ->
	# The different states that the app goes through
	states = {
		initializing: 0 
		insertingImage: 1
		editingImage: 2
		uploadingImage: 3
		generatingLink: 4
	}
	currentState = 0
	$pasteboard = $(pasteboard)
	$imageEditor = null

	setState = (state, stateData = {}) ->
		currentState = state
		switch state
			# State 1: Application is initializing
			when states.initializing
				pasteboard.socketConnection.init()
				pasteboard.modalWindow.init()
				
				setState ++state
			
			# State 2: Waiting for user to insert an image
			when states.insertingImage
				# Set up drag and drop / copy and paste handlers
				pasteboard.dragAndDrop.init()
				pasteboard.copyAndPaste.init()

				# Show the splash screen
				$(".splash").show()

				$pasteboard.on "imageinserted", (e, eventData) ->
					$pasteboard.off "imageinserted"
					setState ++state, image: eventData.image

			# State 3: User is looking at / editing the image
			when states.editingImage

				unless stateData.backtracked
					# Start preuploading the image right away
					pasteboard.fileHandler.preuploadFile()

					# Hide things from the previous state
					pasteboard.dragAndDrop.hide()
					pasteboard.copyAndPaste.hide()
					$(".splash").hide()

					# Display the image editor
					pasteboard.imageEditor.init stateData.image

				$imageEditor.on "cancel.stateevents", (e) ->
					$imageEditor.off ".stateevents"
					# Clear the preuploaded file
					pasteboard.fileHandler.clearFile()
					# Abort the (possibly) ongoing preupload
					pasteboard.fileHandler.abortPreupload()

					pasteboard.imageEditor.hide()
					setState --state

				$imageEditor.on "confirm.stateevents", (e) ->
					$imageEditor.off ".stateevents"
					# Upload the image
					upload = pasteboard.imageEditor.uploadImage()
					setState ++state, upload: upload

			# State 4: The image is uploading
			when states.uploadingImage
				if stateData.upload.inProgress
					# ...
				else
					pasteboard.modalWindow.show("upload-link", null, (modal) ->
						setState ++state, 
							xhr: stateData.upload.xhr,
							modal: modal
					)

			# State 5: The image link is being generated
			when states.generatingLink
				if stateData.xhr
					stateData.xhr.success (data) ->
						stateData.modal.find(".image-link").val(data.url)





			
		
	self =
		start: () ->
			$imageEditor = $(pasteboard.imageEditor)
			setState(0)

window.moduleLoader.addModule "appFlow", appFlow
