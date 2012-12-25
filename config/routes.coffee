###
# Application routing setup
###
app = null

exports.init = (expressApp) ->
	app = expressApp
	controllers = (require "../controllers").init app

	# Go through all controllers and set up their routes.
	# Routes are prefixed with the controller name unless
	# it starts with '/'. The main controller is not prefixed.
	for name, controller of controllers
		setupRoutes name, controller.routes

	# Set the image route last, to give other root routes priority
	app.get "/:image", controllers.images.index

# Create the routes from the routes object in the controller
setupRoutes = (controller, routes) ->
	return unless routes
	for verb, verbRoutes of routes
		for route, method of verbRoutes
			app[verb] (createURL controller, route), method

createURL = (controller, route) ->
	# Main controller
	return "/#{route}" if controller is "main"
	# Routes starting with '/'
	return route if route[0] is "/"
	# Regular route
	return "/#{controller}/#{route}"
