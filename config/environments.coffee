###
# Environment Configuration
###

exports.init = (app, express) ->

    # General
    app.configure ->
        # Use
        app.use (express.favicon "#{__dirname}/../public/images/favicon.ico")
        app.use (express.logger "dev")
        app.use (express.limit "10mb")
        app.use express.cookieParser()
        app.use express.methodOverride()
        app.use app.router
        app.use ((require "connect-assets")())
        app.use (express.static "#{__dirname}/../public")

        # Set
        app.set "localrun", process.env.LOCAL or false
        app.set "port", process.env.PORT or 3000
        # app.set "clients", clients
        app.set "domain", "http://pasteboard.co"
        app.set "views", "#{__dirname}/../views"
        app.set "view engine", "ejs"

    # Development
    app.configure "development", ->
        # Use
        app.use(express.errorHandler());

        # Set
        app.set "port", process.env.PORT or 4000
        app.set "domain", "http://dev.pasteboard.co"
