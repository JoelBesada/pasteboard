###
# Images Controller
###
request = require "request"
auth = require "../auth"
helpers = require "../helpers/common"

get = {}
post = {}

# The image display page
exports.index = get.index = (req, res) ->
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

get.shortURL = (req, res) ->
  return res.send "Short URLs are disabled locally", 500 if req.app.get "localrun"
  longURL = "#{req.app.get "domain"}/#{req.params.image}"
  shortURLRequest = helpers.requestShortURL longURL, (url) ->
    if url
      res.json url: url
    else
      res.send "Unable to get short URL", 500

  res.send "Unable to send short URL request", 500 unless shortURLRequest


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
      require("fs").unlink "#{req.app.get "localStorageFilePath"}#{req.params.image}"

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
    ":image/download": get.download
    ":image/shorturl": get.shortURL
  post:
    ":image/delete": post.delete


