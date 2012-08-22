/*
	App options
*/

// The path where images will be stored when not using Amazon S3
// NOTE: Make sure this folder exists
exports.LOCAL_STORAGE_PATH = __dirname + "/public/storage/";

// The URL that points to the locally stored images folder
exports.LOCAL_STORAGE_URL = "/storage/";

// The domain for the non-local development version of the app
exports.DEVELOPMENT_DOMAIN = "http://dev.pasteboard.co";

// The domain for the non-local production version of the app
exports.PRODUCTION_DOMAIN = "http://pasteboard.co";