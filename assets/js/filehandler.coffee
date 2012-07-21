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
				fd.append "uuid", PasteBoard.UUID
				fd.append "file", dataURLtoBlob data
				$.ajax
					url: "/upload"
					data: fd
					processData: false
					contentType: false
					type: "POST"
					success: (data) ->
						window.location = data.url
					error: (data) ->
						log data

	)() 
)(jQuery)
