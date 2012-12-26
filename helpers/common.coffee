###
# A collection of common helper methods
###

request = require "request"
auth = require "../auth"

# Generates a unique file name with the given file type.
# This current method generates names that are guaranteed
# to be unique for 115 days (10^13 microseconds).
exports.generateFileName = (type) ->
  fileExt = "." + (if type is "jpeg" then "jpg" else type.replace "image/", "")
  timeString = "" + require("microtime").now()
  timeString = timeString.substr timeString.length - 13 # 13 last digits
  return "#{base62Encode parseInt(timeString, 10)}#{fileExt}"

# Creates a cookie to identify the user
# as the image owner.
exports.setImageOwner = (res, image) ->
  key = imageOwnerKey image
  if key
    res.cookie "pb_#{image}", key,
      maxAge: 604800 # 1 week

# Removes the owner from the image,
# usually after the image has been deleted.
exports.removeImageOwner = (res, image) ->
  res.clearCookie "pb_#{image}"

# Checks if the user sending the request
# is the owner of the requested image.
exports.isImageOwner = (req, image) ->
  if key = req.cookies["pb_#{image}"]
    return key is imageOwnerKey image

  return false

# Requests a short URL from Bitly. Bitly doesn't generate
# new short URLs for the same long URL, so this can be used
# to fetch an already generated short URL as well.
exports.requestShortURL = (longURL, callback) ->
  return false unless auth.bitly
  apiEndpoint = "http://api.bitly.com/v3/shorten?login=#{auth.bitly.LOGIN}" +
  "&apiKey=#{auth.bitly.API_KEY}" +
  "&longURL=#{encodeURIComponent longURL}"
  return request apiEndpoint, (error, response, body) ->
    if not error and response.statusCode is 200
      json = JSON.parse body
      if json.status_code is 200
        callback? json.data.url
        return

    callback? false

# Generate the image owner key
imageOwnerKey = (image) ->
  return false unless auth.hashing
  return auth.hashing.keyHash "image"

# Converts an integer from base 10 to 62
base62Encode = (n) ->
  BASE62_CHARS = "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
  arr = []
  return BASE62_CHARS[0] if n is 0
  while n
    r = n % 62
    n = (n - r) / 62
    arr.push BASE62_CHARS[r]

  return arr.reverse().join ""
