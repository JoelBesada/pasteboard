###
# Environment Configuration
###
auth = require "../auth"

exports.init = (app, express) ->
  # General
  app.configure ->
    # Use
    app.use express.favicon("#{__dirname}/../public/images/favicon.ico")
    app.use express.limit("10mb")
    app.use express.logger("dev") if process.env.LOCAL
    app.use express.cookieParser()
    app.use express.methodOverride()
    app.use app.router
    app.use require("connect-assets")()
    app.use express.static("#{__dirname}/../public")

    # Set
    app.set "localrun", process.env.LOCAL or false
    app.set "port", process.env.PORT or 3000
    app.set "domain", "http://pasteboard.co"

    # Amazon S3 connection settings (using knox)
    if auth.amazon
      app.set "knox", require("knox").createClient
        key: auth.amazon.S3_KEY,
        secret: auth.amazon.S3_SECRET,
        bucket: auth.amazon.S3_BUCKET
        region: "eu-west-1"

      app.set "amazonFilePath", "/#{auth.amazon.S3_IMAGE_FOLDER}"

    # File storage options when not using Amazon S3
    app.set "localStorageFilePath", "#{__dirname}/../public/storage/"
    app.set "localStorageURL", "/storage/"

    app.set "views", "#{__dirname}/../views"
    app.set "view engine", "ejs"

  # Development
  app.configure "development", ->
    # Use
    app.use express.errorHandler()

    # Set
    app.set "port", process.env.PORT or 4000
    app.set "domain", "http://dev.pasteboard.co"
