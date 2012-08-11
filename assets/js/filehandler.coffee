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
				pasteboard.imageEditor.init url.createObjectURL(file)
			
			# Else create a data URL
			else if window.FileReader
				fileReader = new FileReader()
				fileReader.onload = (e) ->
					pasteboard.imageEditor.init e.target.result

				fileReader.readAsDataURL file
			
			@preuploadFile()

		# Converts the given data into a file, and sends the data
		# to the image editor
		readData: (data) ->
			currentFile = dataURLtoBlob data
			pasteboard.imageEditor.init data
			@preuploadFile()

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

		# Aborts a preupload
		abortPreupload: () ->
			if preuploadXHR
				preuploadXHR.abort()
				$(pasteboard.socketConnection).off "idReceive"
				preuploadXHR = null

		# Uploads the file. If the file is already preuploaded, just
		# send the client ID so that the server can upload the file to 
		# the cloud.
		uploadFile: (cropSettings, forceUpload) ->
			if preuploadXHR and not forceUpload
				if preuploadXHR.readyState is 4
					postData = 	
						id: pasteboard.socketConnection.getID()
					if cropSettings
						postData.cropImage = true
						postData.crop = cropSettings 

					preuploadXHR = null
					$.post("/upload", postData, (data) ->
							# Temporary way to get to your image
							# log data.url
							window.location = data.url
							
					).error((err) -> log err)
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
								@uploadFile null, true
							else 
								preuploadXHR.addEventListener "load", () =>
									@uploadFile cropSettings

					else
						# Wait for the file to preupload
						preuploadXHR.addEventListener "load", () =>
							@uploadFile
			else
				# Force upload
				$(pasteboard.socketConnection).off "idReceive"
				preuploadXHR.abort() if preuploadXHR
				fd = new FormData()
				fd.append "file", currentFile

				sendFileXHR("/upload", fd).addEventListener("load", (e) ->
					try
						data = JSON.parse(e.target.response)
						window.location = data.url
					catch e
						log e.target.response
				)
					


window.moduleLoader.addModule "fileHandler", fileHandler
