### 
# File handler module, takes care of reading and 
# uploading files.
###

fileHandler = (pasteboard) ->
	FILE_SIZE_LIMIT = 10 * 1024 * 1024 # 10MB
	preuploadXHR = null
	currentFile = null
	currentUploadLoaded = 0

	# Checks the size of the file. If the size
	# exceeds the limit, trigger an error event
	checkFileSize = (file) ->
		if file.size > FILE_SIZE_LIMIT
			$(pasteboard).trigger("filetoolarge")
			return false
		return true

	# Creates an XHR object and sends the given FormData to the url
	sendFileXHR = (url, formData) ->
		onProgress = (e) ->
			currentUploadLoaded = e.loaded
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
		canvas.width = cropSettings.width
		canvas.height = cropSettings.height
		context = canvas.getContext "2d"
		context.drawImage pasteboard.imageEditor.getImage(), -cropSettings.x, -cropSettings.y
		canvas.toBlob callback

	self = 
		isSupported: () -> window.FileReader or window.URL or window.webkitURL
		getCurrentUploadLoaded: () -> currentUploadLoaded
		getFileSizeLimit: () -> FILE_SIZE_LIMIT
		# Reads a file and sends it over to the image editor.
		readFile: (file) ->
			currentFile = file
			if checkFileSize currentFile
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
			if checkFileSize currentFile
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
				cropImage cropSettings, (file) ->
					fd = new FormData()
					fd.append "file", file

					callback xhr: sendFileXHR("/upload", fd), inProgress: true
					


window.moduleLoader.addModule "fileHandler", fileHandler
