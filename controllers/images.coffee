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
    imageURL: helpers.imageURL req, req.params.image
    longURL: "#{req.app.get("domain")}/#{req.params.image}"
    useAnalytics: false
    trackingCode: ""
    isImageOwner: helpers.isImageOwner req, req.params.image

  # Use Google Analytics when not running locally
  if not req.app.get("localrun") and auth.google_analytics
    viewData.useAnalytics = true
    viewData.trackingCode =
      if req.app.settings.env is "development"
      then auth.google_analytics.development
      else auth.google_analytics.production

  res.render "image", viewData

# Image download URL
get.download = (req, res) ->
  imageRequest = request
    url: helpers.imageURL req, req.params.image
    headers:
      "Referer": req.headers.referer

  res.set "Content-Disposition", "attachment; filename=#{req.params.image}"
  imageRequest.pipe res

# Delete the image
post.delete = (req, res) ->
  if helpers.isImageOwner req, req.params.image
    knox = req.app.get "knox"
    if knox
      knox.deleteFile "#{req.app.get "amazonFilePath"}#{req.params.image}", ->
    else
      localPath = "#{req.app.get "localStorageFilePath"}#{req.params.image}"
      require("fs").unlink localPath, (-> )

    if auth.cloudflare
      params =
        url: "https://api.cloudflare.com/client/v4/zones/#{auth.cloudflare.ZONE_ID}/purge_cache"
        json: true
        headers:
          "X-Auth-Email": auth.cloudflare.EMAIL
          "X-Auth-Key": auth.cloudflare.KEY
        body: {
          files: [helpers.imageURL req, req.params.image]
        }

      request.del params, (error) ->
        console.log("Cloudflare error", error) if error

    helpers.removeImageOwner res, req.params.image
    res.send "Success"

  res.send "Forbidden", 403

exports.routes =
  get:
    ":image/download": get.download
  post:
    ":image/delete": post.delete


