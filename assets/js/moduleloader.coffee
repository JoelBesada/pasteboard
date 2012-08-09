###
# The module loader is used to load all the separate
# modules onto the same parent module, without filling up
# the global window object.
###

modules = {}
window.moduleLoader = 
	addModule: (moduleName, module) ->
		modules[moduleName] = module
	loadAll: (parent) ->
		for moduleName, module of modules
			@load moduleName, parent
	load: (module, parent) ->
		parent[module] = modules[module](parent);
		delete modules[module]
