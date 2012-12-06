# Load all controllers
exports.init = (app) ->
	((require "fs").readdirSync __dirname).forEach (file) ->
		controllerName = file.replace /\.(coffee|js)$/, ""
		unless controllerName is "index"
			controller = require "#{__dirname}/#{controllerName}"
			controller.init? app
			exports[controllerName] = controller

	delete this.init
	return this
