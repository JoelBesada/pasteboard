###
# Application routing setup
###
app = null
exports.init = (expressApp) ->
	app = expressApp
	controllers = (require "../controllers").init app
	for name, controller of controllers
		name = "" if name is "main"
		setupRoutes name, controller.routes

setupRoutes = (path, routes) ->
	return unless routes
	for verb, verbRoutes of routes
		for url, method of verbRoutes
			app[verb] "#{path}/#{url}", method


	# # GET
	# app.get('/', main.index);
	# app.get('/redirected', routes.redirected);
	# app.get('/download/:image', routes.download);
	# app.get('/shorturl/:image', routes.shorturl);
	# app.get('/imageproxy/:image', routes.imageproxy);
	# app.get('/:image', routes.image);

	# # POST
	# app.post('/upload', routes.upload);
	# app.post('/preupload', routes.preupload);
	# app.post('/clearfile', routes.clearfile);
	# app.post('/delete/:image', routes["delete"]);
