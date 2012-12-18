###
# Images Controller
###
request = require "request"
auth = require "../auth"
helpers = require "../helpers/common"

get = {}
post = {}

# The image display page
get.index = (req, res) ->
	viewData =
		imageName: req.params.image
		imageURL: imageURL req
		useAnalytics: false
		trackingCode: ""
		isImageOwner: helpers.isImageOwner req, req.params.image

	# Use Google Analytics when not running locally
	if not req.app.get "localrun" and auth.google_analytics
		viewData.useAnalytics = true
		viewData.trackingCode =
			if req.app.settings.env is "development"
			then auth.google_analytics.development
			else auth.google_analytics.production

	res.render "image", viewData

# Get the short URL for the image
get.shortURL = (req, res) ->
	unless auth.parse
		res.send "Missing Parse.com credentials", 500
		return

	query = encodeURIComponent "{\"fileName\":\"#{req.params.image}\"}"
	params =
		method: "GET"
		uri: "https://api.parse.com/1/classes/short_url?where=#{query}"
		headers: {
      		"X-Parse-REST-API-Key": auth.parse.API_KEY
			"X-Parse-Application-Id": auth.parse.APP_ID
		}

	request params, (err, response, body) ->
		if not err and response.statusCode is 200
			result = (JSON.parse body).results[0]
			if result
				res.json url: result.shortURL
				return

		res.send "Not found", 500

# Image download URL
get.download = (req, res) ->
	imageRequest = request
		url: imageURL req
		headers:
			"Referer": req.headers.referer

	res.set "Content-Disposition", "attachment"
	imageRequest.pipe res

# Delete the image
post.delete = (req, res) ->
	if helpers.isImageOwner req, req.params.image
		knox = req.app.get "knox"
		if knox
			knox.deleteFile "#{req.app.get "amazonFilePath"}#{req.params.image}", ->
		else
			(require "fs").unlink "#{req.app.get "localStorageFilePath"}#{req.params.image}"

		helpers.removeImageOwner res, req.params.image
		res.send "Success"

	res.send "Forbidden", 403

imageURL = (req) ->
	if auth.amazon
		return "#{req.app.get "amazonURL"}#{req.app.get "amazonFilePath"}#{req.params.image}"
	else
		return "http://#{req.headers.host}#{req.app.get "localStorageURL"}#{req.params.image}"


exports.routes =
	get:
		"/:image": get.index
		":image/download": get.download
		":image/shorturl": get.shortURL
	post:
		":image/delete": post.delete


