### 
# File handler module, takes care of reading and 
# uploading files.
###

fileHandler = (pasteboard) ->
	preuploadXHR = null
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
		# Returns true for successful reads, else false
		readFile: (file) ->
			if window.FileReader
				fileReader = new FileReader()
				fileReader.onload = (e) ->
					pasteboard.imageEditor.init e.target.result, file.type

				fileReader.readAsDataURL file
				return true
			# FileReader fallback
			else if url = window.URL || window.webkitURL
				pasteboard.imageEditor.init url.createObjectURL(file), file.type
				return true

			return false

		# Converts the data to a file object and uploads
		# it to the server, while tracking the progress.
		#
		# TODO: Hold upload until an ID has been given
		# (force upload if no ID has been received before upload is clicked)
		preuploadFile: (imageData) ->
			id = pasteboard.socketConnection.getID()
			$(pasteboard.socketConnection).off "idReceive" 

			if id
				fd = new FormData()
				fd.append "id", pasteboard.socketConnection.getID()
				fd.append "file", dataURLtoBlob imageData

				preuploadXHR = sendFileXHR "/preupload", fd
			else
				log "no id"
				$(pasteboard.socketConnection).on "idReceive", () -> self.preuploadFile imageData

		abortPreupload: () ->
			if preuploadXHR
				preuploadXHR.abort()
				$(pasteboard.socketConnection).off "idReceive"
				preuploadXHR = null

		uploadFile: (imageData) ->
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
				fd.append "file", dataURLtoBlob imageData

				sendFileXHR "/upload", fd


window.moduleLoader.addModule "fileHandler", fileHandler
