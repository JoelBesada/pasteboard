###
# Google Analytics API Wrapper
# Based on https://gist.github.com/PaquitoSoft/4451865
###

fs = require "fs"
crypto = require "crypto"

_ = require "underscore"
request = require "request"

auth = require "../auth"

SIGNATURE_ALGORITHM = "RSA-SHA256"
SIGNATURE_ENCODE_METHOD = "base64"

API_URL = "https://www.googleapis.com/analytics/v3/data/ga"

authHeader = {
  "alg": "RS256"
  "typ": "JWT"
}

authClaimSet = {
  "iss": auth.google_analytics?.SERVICE_ACCOUNT_EMAIL
  "scope": "https://www.googleapis.com/auth/analytics.readonly"
  "aud": "https://accounts.google.com/o/oauth2/token"
}

key = null
token = {}

urlEscape = (source) ->
  source.replace(/\+/g, "-").replace(/\//g, "_").replace /\=+$/, ""

base64Encode = (obj) ->
  encoded = new Buffer(JSON.stringify(obj), "utf8").toString("base64")
  urlEscape encoded

readPrivateKey = ->
  key = key || fs.readFileSync(auth.google_analytics.KEY_PATH, "utf8")

authorize = (callback) ->
  unless auth.google_analytics
    return _.defer(callback, new Error "Missing Google Analytics Credentials")

  now = parseInt(Date.now() / 1000, 10)

  if token and token.expires > now
    return _.defer(callback, null, token.value)

  signatureKey = readPrivateKey()

  authClaimSet.iat = now
  authClaimSet.exp = now + 60

  signatureInput = base64Encode(authHeader) + "." + base64Encode(authClaimSet)

  cipher = crypto.createSign "RSA-SHA256"
  cipher.update signatureInput
  signature = cipher.sign signatureKey, "base64"
  jwt = signatureInput + "." + urlEscape signature

  request
    method: "POST"
    headers:
      "Content-Type": "application/x-www-form-urlencoded"

    uri: "https://accounts.google.com/o/oauth2/token"
    body: "grant_type=" +
      escape("urn:ietf:params:oauth:grant-type:jwt-bearer") +
      "&assertion=" + jwt

  , (error, response, body) ->
    if error
      callback new Error(error)
    else
      result = JSON.parse(body)
      if result.error
        callback new Error(result.error)
      else
        token = {
          value: result.access_token
          expires: now + result.expires_in
        }

        callback null, token.value

# Fetch the total number of unique page views for the given path
exports.getTotalViews = (path, callback) ->
  authorize (err, token) ->
    return console.log err if err

    request
      method: "GET"
      headers:
        "Authorization": "Bearer #{token}"
      qs:
        "ids": auth.google_analytics.PROFILE_ID
        "start-date": "2005-01-01"
        "end-date": "9999-12-31"
        "dimensions": "ga:pagePath"
        "metrics": "ga:uniquePageviews"
        "filters": "ga:pagePath==#{path}"
      uri: API_URL
    , (err, res, body) ->
      return callback err if err
      data = JSON.parse(body)
      return callback data.error if data.error

      callback null, data.rows?[0]?[1]
