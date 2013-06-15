###
# Analytics Controller
###

analytics = require "../helpers/analytics"

get = {}

get.views = (req, res) ->
  analytics.getTotalViews "/#{req.params.path}", (err, views) ->
    return res.send err, 500 if err
    res.send views: views

exports.routes =
  get:
    "views/:path": get.views