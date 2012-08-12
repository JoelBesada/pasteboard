### 
# File handler module, takes care of reading and 
# uploading files.
###

fileHandler = (pasteboard) ->
	preuploadXHR = null
	currentFile = null
	currentUploadProgress = 0

	# Creates an XHR object and sends the given FormData to the url
	sendFileXHR = (url, formData) ->
		onProgress = (e) ->
			currentUploadProgress = e.loaded / e.total
			log "#{Math.floor(currentUploadProgress * 100)}%"
		onSuccess = (e) ->
			log e.target.response
		onError = (e) ->
			log "Error: ", e

		xhr = new XMLHttpRequest()
		xhr.upload.addEventListener "progress", onProgress
		xhr.addEventListener "load", onSuccess
		xhr.addEventListener "error", onError
		xhr.open "POST", url
		xhr.send formData
		return xhr

	self = 
		isSupported: () -> window.FileReader or window.URL or window.webkitURL
		
		# Reads a file and sends it over to the image editor.
		readFile: (file) ->
			currentFile = file
			# Try creating a file URL first
			if url = window.URL || window.webkitURL
				$(pasteboard).trigger "imageinserted", image: url.createObjectURL(file)
			
			# Else create a data URL
			else if window.FileReader
				fileReader = new FileReader()
				fileReader.onload = (e) ->
					$(pasteboard).trigger "imageinserted", image: e.target.result

				fileReader.readAsDataURL file
			

		# Converts the given data into a file, and sends the data
		# to the image editor
		readData: (data) ->
			currentFile = dataURLtoBlob data
			$(pasteboard).trigger "imageinserted", image: data

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
				log "no id"
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
		uploadFile: (cropSettings, forceUpload) ->
			if preuploadXHR and not forceUpload
				# Image is already uploaded
				if preuploadXHR.readyState is 4
					postData = 	
						id: pasteboard.socketConnection.getID()
					if cropSettings
						postData.cropImage = true
						postData.crop = cropSettings 

					preuploadXHR = null
					
					return xhr: $.post("/upload", postData), inProgress: false
				else 
					if cropSettings
						# Estimate if it's faster to wait for the
						# preupload to finish and crop the image server-side,
						# or send a new cropped image instead
						
						remainingSize = (1.0 - currentUploadProgress) * currentFile.size
						
						# Crop the image and check the file size
						canvas = document.createElement "canvas"
						canvas.width = cropSettings.width
						canvas.height = cropSettings.height
						context = canvas.getContext "2d"
						context.drawImage pasteboard.imageEditor.getImage(), -cropSettings.x, -cropSettings.y
						canvas.toBlob (blob) => 
							# Add 10% to the cropped size when comparing
							# to make sure we'll benefit from reuploading
							# the cropped part (might need some tweaking)
							if blob.size * 1.1 < remainingSize
								currentFile = blob;
								# Reupload cropped part
								return @uploadFile null, true
							else 
								xhr = preuploadXHR.addEventListener "load", () =>
									@uploadFile cropSettings

								return xhr: xhr, inProgress: true
					else
						# Wait for the file to preupload
						xhr = preuploadXHR.addEventListener "load", () =>
							@uploadFile()

						return xhr: xhr, inProgress: true
			else
				# Force upload
				$(pasteboard.socketConnection).off "idReceive"
				preuploadXHR.abort() if preuploadXHR
				fd = new FormData()
				fd.append "file", currentFile

				return xhr: sendFileXHR("/upload", fd), inProgress: true
					


window.moduleLoader.addModule "fileHandler", fileHandler
