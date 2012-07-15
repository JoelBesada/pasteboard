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
	)() 
)(jQuery)
