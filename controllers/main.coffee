###
# Main (Index) Controller
###
auth = require "../auth"
request = require "request"

get = {}
post = {}

# The index page, where all the magic happens :)
get.index = (req, res) ->
	viewData =
	    port: req.app.get "port"
	    redirected: false
	    useAnalytics: false
	    trackingCode: ""

	# Use Google Analytics when not running locally
	if not req.app.get "localrun" and auth.google_analytics
		viewData.useAnalytics = true
		viewData.trackingCode =
			if req.app.settings.env is "development"
			then auth.google_analytics.development
			else auth.google_analytics.production

	# Show a welcome banner for redirects from PasteShack
	if req.cookies.redirected
		viewData.redirected = true
		res.clearCookie "redirected"

	res.render "index", viewData

# Handle redirects from PasteShack
get.redirected = (req, res) ->
	res.cookie "redirected", true
	res.redirect "/"


# Proxy for external images, used get around
# cross origin restrictions
get.imageProxy = (req, res) ->
	try
		(request (decodeURIComponent req.params.image)).pipe res
	catch e
		res.send "Failure", 500


exports.routes =
	get:
		"": get.index
		"redirected": get.redirected
		"imageproxy/:image": get.imageProxy
