(($) ->
	PasteBoard.FileHandler = (() ->
		self = 
			readFile: (file) ->
				if window.FileReader
					fileReader = new FileReader()
					fileReader.onload = (e) ->
						PasteBoard.ImageEditor.init e.target.result, file.type

					fileReader.readAsDataURL file
					return true
				else if url = window.URL || window.webkitURL
					PasteBoard.ImageEditor.init url.createObjectURL(file), file.type
					return true

				return false

			uploadFile: (data) ->
				fd = new FormData()
				fd.append "file", dataURLtoBlob data

				onProgress = (e) ->
					log "#{Math.floor (e.loaded / e.total) * 100}%"
				onSuccess = (e) ->
					data = JSON.parse(e.target.response);
					log data.url
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
