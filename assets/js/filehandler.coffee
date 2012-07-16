(($) ->
	PasteBoard.FileHandler = (() ->
		self = 
			readFile: (file) ->
				if window.FileReader
					fileReader = new FileReader()
					fileReader.onload = (e) ->
						PasteBoard.ImageEditor.init e.target.result

					fileReader.readAsDataURL file
					return true
				else if url = window.URL || window.webkitURL
					PasteBoard.ImageEditor.init url.createObjectURL(file)
					return true

				return false

			uploadFile: (data) ->
				$.post("/upload", { url: data }, (data) ->
					log data
					window.location = data.url
				).error (data) ->
					log data.responseText
	)() 
)(jQuery)
