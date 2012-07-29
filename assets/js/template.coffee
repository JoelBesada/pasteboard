(($) ->
	# Micro-templating engine based on John Resig's blog post "JavaScript Micro-Templating"
	# http://ejohn.org/blog/javascript-micro-templating/
	pasteBoard.template = (()->
		cache = {}
		loading = {}
		compile = (str, data) ->
			(new Function("obj",
		        "var p=[],print=function(){p.push.apply(p,arguments);};" +
		        "with(obj){p.push('" +
		        str
		          .replace(/[\r\t\n]/g, " ")
		          .split("<%").join("\t")
		          .replace(/((^|%>)[^\t]*)'/g, "$1\r")
		          .replace(/\t=(.*?)%>/g, "',$1,'")
		          .split("\t").join("');")
		          .split("%>").join("p.push('")
		          .split("\r").join("\\'") + "');}return p.join('');"))(data)

				
		self = 
			load: (templateURL) ->
				return loading[templateURL] if loading[templateURL]
				loading[templateURL] = $.get(templateURL)
					.success((loadedTemplate) ->
						 cache[templateURL] = loadedTemplate
						 delete loading[templateURL]
					).error((error) ->
						log "Error: ", error
					)
				
			compile: (str, data, fn) ->
				isTemplateFile = /^(\w|\/)*\.tmpl$/.test str
				if isTemplateFile
					if cache[str]
						fn compile(cache[str], data)
					else
						this.load(str)
							.success((loadedTemplate) ->
								fn compile loadedTemplate, data
							)
				else
					fn compile(str, data)

				return true
		
	)()
)(jQuery)