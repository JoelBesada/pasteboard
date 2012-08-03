
### 
# File handler module, takes care of reading and 
# uploading files.
###

(($) ->
	pasteboard.fileHandler = (() ->
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
			uploadFile: (data) ->
				fd = new FormData()
				fd.append "file", dataURLtoBlob data

				onProgress = (e) ->
					log "#{Math.floor (e.loaded / e.total) * 100}%"
				onSuccess = (e) ->
					try 
						data = JSON.parse(e.target.response);
						log data.url
						
						# Temporary way to get to your image
						window.location = data.url
					catch err
						log "returned non-json"
						log e.target.response

				onError = (e) ->
					log "Error: ", e


				xhr = new XMLHttpRequest();
				xhr.upload.addEventListener "progress", onProgress
				xhr.addEventListener "load", onSuccess
				xhr.addEventListener "error", onError
				xhr.open "POST", "/upload"
				xhr.send fd

	)() 	
)(jQuery)
