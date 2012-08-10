### 
# File handler module, takes care of reading and 
# uploading files.
###

fileHandler = (pasteboard) ->
	preuploadXHR = null
	currentFile = null

	# Creates an XHR object and sends the given FormData to the url
	sendFileXHR = (url, formData) ->
		onProgress = (e) ->
			log "#{Math.floor (e.loaded / e.total) * 100}%"
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
				pasteboard.imageEditor.init url.createObjectURL(file), file.type
			
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
				$(pasteboard.socketConnection).on "idReceive", () -> self.preuploadFile imageData

		# Aborts a preupload
		abortPreupload: () ->
			if preuploadXHR
				preuploadXHR.abort()
				$(pasteboard.socketConnection).off "idReceive"
				preuploadXHR = null

		# Uploads the file. If the file is already preuploaded, just
		# send the client ID so that the server can upload the file to 
		# the cloud.
		uploadFile: () ->
			if preuploadXHR 
				if preuploadXHR.readyState is 4
					preuploadXHR = null
					$.post("/upload", { id: pasteboard.socketConnection.getID() }, (data) ->
							# Temporary way to get to your image
							window.location = data.url
							
					).error((err) -> log err)
				else 
					# Wait for the file to preupload
					preuploadXHR.addEventListener "load", @uploadFile
			else
				$(pasteboard.socketConnection).off "idReceive"
				
				# Force upload
				fd = new FormData()
				fd.append "file", currentFile

				sendFileXHR "/upload", fd


window.moduleLoader.addModule "fileHandler", fileHandler
