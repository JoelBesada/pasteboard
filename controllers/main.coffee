###
# Main (Index) Controller
###
fs = require "fs"
async = require "async"
request = require "request"
formidable = require "formidable"
auth = require "../auth"
helpers = require "../helpers/common"

FILE_SIZE_LIMIT = 10 * 1024 * 1024 # 10 MB

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
  if not req.app.get("localrun") and auth.google_analytics
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

# Preuploads an image and stores it in /tmp
post.preupload = (req, res) ->
  form = new formidable.IncomingForm()
  incomingFiles = []

  form.on "fileBegin", (name, file) ->
    incomingFiles.push file

  form.on "aborted", ->
    # Remove temporary files that were in the process of uploading
    for file in incomingFiles
      fs.unlink file.path

  form.parse req, (err, fields, files) ->
    client = req.app.get("clients")[fields.id]
    if client
      # Remove the old file
      fs.unlink client.file.path if client.file
      client.file = files.file

    res.send "Received file"

# Upload the file to the cloud (or to a local folder).
# If the file has been preuploaded, upload that, else
# upload the file that should have been posted with the
# request.
post.upload = (req, res) ->
  form = new formidable.IncomingForm()
  knox = req.app.get "knox"
  incomingFiles = []

  form.parse req, (err, fields, files) ->
    client = req.app.get("clients")[fields.id] if fields.id

    # Check for either a posted or preuploaded file
    if files.file
      file = files.file
    else if client and client.file and not client.uploading[client.file.path]
      file = client.file
      client.uploading[file.path] = true

    return res.send "Missing file", 500 unless file
    return res.send "File too large", 500 if file.size > FILE_SIZE_LIMIT

    fileName = helpers.generateFileName(file.type.replace "image/", "")
    domain = if req.app.get "localrun" then req.headers.host else req.app.get "domain"
    longURL = "#{domain}/#{fileName}"
    sourcePath = file.path

    parallels = {}
    unless req.app.get "localrun"
      # Request a short URL
      parallels.shortURL = (callback) ->
        helpers.requestShortURL longURL, (url) ->
          callback null, url

    if knox
      # Upload to amazon
      parallels.upload = (callback) ->
        knox.putFile(
          sourcePath,
          "#{req.app.get "amazonFilePath"}#{fileName}",
            "Content-Type": file.type
            "x-amz-acl": "private"
          ,
          callback
        )
    else
      # Upload to local file storage
      parallels.upload = (callback) ->
        fs.rename(
          sourcePath,
          "#{req.app.get "localStorageFilePath"}#{fileName}",
          callback
        )

    series = []
    if fields.cropImage
      series.push (callback) ->
        cropPath = "/tmp/#{fileName}"
        require("easyimage").crop(
          src: sourcePath
          dst: cropPath
          cropwidth: fields["crop[width]"]
          cropheight: fields["crop[height]"]
          x: fields["crop[x]"]
          y: fields["crop[y]"]
          gravity: "NorthWest"
        , ->
          fs.unlink sourcePath
          sourcePath = cropPath
          callback null
        )

    series.push (callback) ->
      async.parallel parallels, (err, results) ->
        return res.send "Failed to upload file", 500 if err
        fs.unlink sourcePath
        helpers.setImageOwner res, fileName
        res.json
          url: results.shortURL or longURL
        callback null

    async.series series

  form.on "fileBegin", (name, file) ->
    incomingFiles.push file

  form.on "aborted", ->
    # Remove temporary files that were in the process of uploading
    fs.unlink incomingFile.path for incomingFile in incomingFiles


# Remove a preuploaded file from the given client ID, called
# whenever an image is discarded or the user leaves the site
post.clearfile = (req, res) ->
  form = new formidable.IncomingForm()
  form.parse req, (err, fields, files) ->
    client = req.app.get("clients")[fields.id]
    if client and client.file
      fs.unlink client.file.path
      client.file = null;
    res.send "Cleared"

exports.routes =
  get:
    "": get.index
    "redirected": get.redirected
    "imageproxy/:image": get.imageProxy
  post:
    "upload": post.upload
    "clearfile": post.clearfile
    "preupload": post.preupload
