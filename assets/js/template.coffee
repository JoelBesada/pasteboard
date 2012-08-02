
### 
#	Micro-templating engine based on John Resig's 
#	blog post "JavaScript Micro-Templating":
#	http://ejohn.org/blog/javascript-micro-templating/
# 
#	Loads, caches and compiles templates. The compiled
#	template is NOT cached, just the template itself.
###

(($) ->
	
	pasteBoard.template = (()->
		cache = {}
		loading = {}
		compile = (str, data) ->
			# RegEx magic combined with the Function constructor code evaluator
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
			# Loads a template and adds it to the cache.
			# Returns the jquery XHR object to allow
			# more event listeners to be added.
			# 	TODO: handle load on already cached template
			load: (templateURL) ->
				# Prevent multiple loads on the same template
				return loading[templateURL] if loading[templateURL]
				loading[templateURL] = $.get(templateURL)
					.success((loadedTemplate) ->
						 cache[templateURL] = loadedTemplate
						 delete loading[templateURL]
					).error((error) ->
						log "Error: ", error
					)
			
			# Compiles a template with the given data object
			# and calls the callback function with the result.
			#
			# The template parameter can either be a file name
			# (.tmpl) or a direct template string.
			compile: (template, data, callback) ->
				isTemplateFile = /^(\w|\/)*\.tmpl$/.test template
				if isTemplateFile
					if cache[template]
						callback compile(cache[template], data)
					else
						this.load(template)
							.success((loadedTemplate) ->
								callback compile loadedTemplate, data
							)
				else
					callback compile(template, data)

				return true
		
	)()
)(jQuery)