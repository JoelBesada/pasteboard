###
# File handler module, takes care of reading and
# uploading files.
###

fileHandler = (pasteboard) ->
	FILE_SIZE_LIMIT = 10 * 1024 * 1024 # 10MB
	preuploadXHR = null
	currentFile = null
	currentUploadLoaded = 0
	currentUploadRatio = 0

	# Checks the size of the file. If the size
	# exceeds the limit, trigger an error event
	checkFileSize = (file, action) ->
		if file.size > FILE_SIZE_LIMIT
			$(pasteboard).trigger "filetoolarge",
				size: file.size
				action: action
			return false
		return true

	# Creates an XHR object and sends the given FormData to the url
	sendFileXHR = (url, formData) ->
		onProgress = (e) ->
			currentUploadLoaded = e.loaded
			currentUploadRatio = e.loaded / e.total
		onError = (e) ->
			log "Error: ", e

		xhr = new XMLHttpRequest()
		xhr.upload.addEventListener "progress", onProgress
		xhr.addEventListener "error", onError
		xhr.open "POST", url
		xhr.send formData
		return xhr

	# Crops an image and returns the new file with the callback
	# (If no crop settings are given, the callback is called with
	# the current, uncropped file)
	cropImage = (cropSettings, callback) ->
		return callback currentFile unless cropSettings

		canvas = document.createElement "canvas"
		return callback currentFile, true unless canvas.toBlob

		canvas.width = cropSettings.width
		canvas.height = cropSettings.height
		context = canvas.getContext "2d"
		context.drawImage pasteboard.imageEditor.getImage(), -cropSettings.x, -cropSettings.y
		canvas.toBlob callback

	self =
		isSupported: () -> !!(window.FileReader or window.URL or window.webkitURL)
		getCurrentUploadLoaded: () -> currentUploadLoaded
		getCurrentUploadRatio: () -> currentUploadRatio
		getFileSizeLimit: () -> FILE_SIZE_LIMIT
		# Reads a file and sends it over to the image editor.
		readFile: (file, action) ->
			currentFile = file
			if checkFileSize currentFile, action
				# Try creating a file URL first
				if url = window.URL || window.webkitURL
					objectURL = url.createObjectURL(file)

					# Opera just returns the file again, why?
					if typeof objectURL is "string"
						$(pasteboard).trigger "imageinserted",
							image: objectURL
							action: action
							size: currentFile.size

						return

				# Else create a data URL
				if window.FileReader
					fileReader = new FileReader()
					fileReader.onload = (e) ->
						$(pasteboard).trigger "imageinserted",
							image: e.target.result
							action: action
							size: currentFile.size

					fileReader.readAsDataURL file

		# Capture an image from the input video
		readVideo: (video) ->
			canvas = document.createElement "canvas"
			canvas.width = video.videoWidth
			canvas.height = video.videoHeight
			canvas.getContext("2d").drawImage video, 0, 0
			canvas.toBlob (blob) ->
				currentFile = blob
				if checkFileSize currentFile, "webcam"
					$(pasteboard).trigger "imageinserted",
						image: canvas.toDataURL "image/png"
						action:
							webcam: true
						size: currentFile.size

		# Converts the given data into a file, and sends the data
		# to the image editor
		readData: (data, action) ->
			currentFile = dataURLtoBlob data
			if checkFileSize currentFile, action
				$(pasteboard).trigger "imageinserted",
					image: data
					action: action
					size: currentFile.size

		# Reads data from an external image url and creates a file
		readExternalImage: (url, action) ->
			# Use a local proxy to access the image to avoid going against
			# canvas cross origin policies.
			proxyURL = "/imageproxy/" + encodeURIComponent(url)
			image = new Image()
			image.onload = () ->
				canvas = document.createElement "canvas"

				return $(pasteboard).trigger "noimagefound", action unless canvas.toBlob

				canvas.width = image.width
				canvas.height = image.height
				context = canvas.getContext "2d"
				context.drawImage image, 0, 0
				canvas.toBlob (blob) ->
					currentFile = blob
					if checkFileSize currentFile, action
						$(pasteboard).trigger "imageinserted",
							image: proxyURL
							action: action
							size: currentFile.size


			image.onerror = (err) ->
				$(pasteboard).trigger "noimagefound", action

			image.src = proxyURL

		# Converts the data to a file object and uploads
		# it to the server, while tracking the progress.
		preuploadFile: () ->
			id = pasteboard.socketConnection.getID()
			$(pasteboard.socketConnection).off "idReceive"
			if id
				fd = new FormData()
				fd.append "id", pasteboard.socketConnection.getID()
				fd.append "file", currentFile
				preuploadXHR = sendFileXHR "/preupload", fd
			else
				$(pasteboard.socketConnection).on "idReceive", self.preuploadFile

		# Aborts the preupload
		abortPreupload: () ->
			if preuploadXHR
				preuploadXHR.abort()
				$(pasteboard.socketConnection).off "idReceive"
				preuploadXHR = null

		# Clears partially or preuploaded files from the server
		clearFile: () ->
			$.post("/clearfile",
				id: pasteboard.socketConnection.getID()
			);

		# Uploads the file. If the file is already preuploaded, just
		# send the client ID so that the server can upload the file to
		# the cloud.
		uploadFile: (cropSettings, callback) ->
			if preuploadXHR
				# The image is already uploaded
				if preuploadXHR.readyState is 4
					postData =
						id: pasteboard.socketConnection.getID()
					if cropSettings
						postData.cropImage = true
						postData.crop = cropSettings

					preuploadXHR = null
					xhr = $.post("/upload", postData)
							.error((error) -> log error)

					callback xhr: xhr, inProgress: false
				# The image is preuploading
				else
					if cropSettings
						# Estimate if it's faster to wait for the
						# preupload to finish and crop the image server-side,
						# or send a new cropped image instead

						remainingSize = currentFile.size - currentUploadLoaded

						# Crop the image and check the file size
						cropImage cropSettings, (blob) =>
							# Add 10% to the cropped size when comparing
							# to make sure we'll benefit from reuploading
							# the cropped part (might need some tweaking)
							if blob.size * 1.1 < remainingSize
								# Reupload cropped part
								currentFile = blob;
								preuploadXHR.abort()
								preuploadXHR = null
								@uploadFile null, callback
							else
								callback xhr: preuploadXHR, inProgress: true, preuploading: true
					else
						callback xhr: preuploadXHR, inProgress: true, preuploading: true
			else
				# Force upload
				$(pasteboard.socketConnection).off "idReceive"

				# This only crops if we have crop settings
				cropImage cropSettings, (file, doServerCrop) ->
					fd = new FormData()
					fd.append "file", file
					# Couldn't crop on client
					if doServerCrop
						fd.append "cropImage", true
						fd.append "crop[#{key}]", val for key, val of cropSettings

					callback xhr: sendFileXHR("/upload", fd), inProgress: true



window.moduleLoader.addModule "fileHandler", fileHandler
