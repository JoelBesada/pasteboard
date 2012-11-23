/**
 * A collection of common helper methods.
 */

var microtime = require("microtime"),
	auth = require("../auth");

/**
   Generates a unique file name with the given file type.
   This current method generates names that are guaranteed
   to be unique for 115 days (10^13 microseconds).
 */
exports.generateFileName = function(type) {
	var fileExt = "." + (type === "jpeg" ? "jpg" : type.replace("image/", "")),
		timeString = "" + microtime.now();

	timeString = timeString.substr(timeString.length - 13); // 13 last digits
	return base62Encode(parseInt(timeString, 10)) + fileExt;
};

/**
 * Creates a cookie to identify the user
 * as the image owner.
 */
exports.setImageOwner = function(res, image) {
	var key = imageOwnerKey(image);
	if (key) res.cookie("pb_" + image, key, { maxAge: 3600000} );
};

/**
 * Removes the owner from the image,
 * usually after the image has been deleted.
 */
exports.removeImageOwner = function(res, image) {
	res.clearCookie("pb_" + image);
};

/**
 * Checks if the user sending the request
 * is the owner of the requested image.
 */
exports.isImageOwner = function(req, image) {
	var key;
	if ((key = req.cookies["pb_" + image])) {
		return key === imageOwnerKey(image);
	}
	return false;
};

function imageOwnerKey(image) {
	if (!auth.hashing) return false;
	return auth.hashing.keyHash(image);
}

/**
 * Converts an integer from base 10 to 62
 */
function base62Encode(n) {
	var BASE62_CHARS = "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ",
		arr = [],
		r;

	if (n === 0) return BASE62_CHARS[0];

	while (n) {
		r = n % 62;
		n = (n - r) / 62;
		arr.push(BASE62_CHARS[r]);
	}

	return arr.reverse().join("");
}