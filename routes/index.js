var knox = require("knox"),
	formidable = require("formidable"),
	microtime = require("microtime"),
	easyimage = require("easyimage"),
	request = require('request'),
	fs = require('fs'),
	auth = require('../auth'),
	knoxClient = null,
	FILE_SIZE_LIMIT = 10 * 1024 * 1024; // 10 MB

if (auth.amazon) {
	knoxClient = knox.createClient({
			key: auth.amazon.S3_KEY,
			secret: auth.amazon.S3_SECRET,
			bucket: auth.amazon.S3_BUCKET
		});
}

/* GET home page */
exports.index =  function(req, res) {
	res.render("index", { port: req.app.get("port") });
};

exports.image = function(req, res) {
	res.render("image", { imageURL: "http://" + auth.amazon.S3_BUCKET + ".s3.amazonaws.com/images/" + req.params.image });
};

/* POST, preuploads an image and stores it in /tmp */
exports.preupload = function(req, res) {
	var form = new formidable.IncomingForm(),
		incomingFiles = [];
	
	form.parse(req, function(err, fields, files) {
		var client = req.app.get("clients")[fields.id];
		if (client) {
			if (client.file) {
				// Remove the old file
				fs.unlink(client.file.path);
			}
			// Keep track of the current pre-uploaded file
			client.file = files.file;
		}
		res.send("Received file");

	});
	form.on("fileBegin", function(name, file) {
		incomingFiles.push(file);
	});
	form.on("aborted", function() {
		// Remove temporary files that were in the process of uploading
		for (var i = 0; i < incomingFiles.length; i++) {
			fs.unlink(incomingFiles[i].path);
		}
	});
};

/* POST, removes a preuploaded file from the given client ID */
exports.clearfile = function(req, res) {
	var form = new formidable.IncomingForm();
	form.parse(req, function(err, fields, files) {
		var client = req.app.get("clients")[fields.id];
		if (client && client.file) {
			fs.unlink(client.file.path);
			client.file = null;
		}
		res.send("Cleared");
	});
};

/* POST, uploads a file to Amazon S3.
   If a file has been preuploaded, upload that, else
   upload the file that should have been posted with this request */

exports.upload = function(req, res) {
	if (knoxClient) {
		var form = new formidable.IncomingForm(),
			incomingFiles = [];

		form.parse(req, function(err, fields, files) {
			var client,
				file,
				fileType,
				fileExt,
				fileName,
				targetPath,
				cropPath,
				uploadToAmazon,
				longURL,
				shortURL,
				shortURLRequest,
				canvas;

			if (fields.id) {
				client = req.app.get("clients")[fields.id];
			}

			// Check for either a posted or preuploaded file
			if (files.file) {
				file = files.file;
			} else if (client && client.file && !client.uploading[client.file.path]) {
				file = client.file;
				client.uploading[file.path] = true;
			}
			if (file) {
				if (file.size > FILE_SIZE_LIMIT) {
					res.send("File too large", 500);
					return;
				}

				fileType = file.type;
				fileExt = fileType.replace("image/", "");
				// Use microtime to generate a unique file name
				fileName = microtime.now() + "." + (fileExt === "jpeg" ? "jpg" : fileExt);
				targetPath = "/images/" + fileName;
				longURL = req.app.get("domain") + "/" + fileName;

				// Start requesting a short URL
				if(auth.bitly) {
					shortURLRequest = request("http://api.bitly.com/v3/shorten?login=" +
							auth.bitly.LOGIN + "&apiKey=" + auth.bitly.API_KEY +
							"&longUrl=" + encodeURIComponent(longURL),
					function(error, response, body){
						var json;
						if (!error && response.statusCode === 200) {
							json = JSON.parse(body);
							if (json.status_code === 200) {
								shortURL = json.data.url;
								return;
							}
						}
						shortURL = false;
						return;
					});
				}
				
				uploadToAmazon = function(sourcePath) {
					knoxClient.putFile(
						sourcePath,
						targetPath,
						{ "Content-Type": fileType },
						function(err, putRes) {
							if (putRes) {
								fs.unlink(sourcePath); // Remove tmp file
								if (putRes.statusCode === 200) {
									if(shortURL === false || !shortURLRequest) {
										res.json({url: longURL});
									} else if (shortURL === undefined) {
										shortURLRequest.on("complete", function(response) {
											var json;
											if (response.statusCode === 200) {
												json = JSON.parse(response.body);
												if (json.status_code === 200) {
													res.json({url: json.data.url});
													return;
												}
											}
											res.json({url: longURL});
										}).on("error", function() {
											res.json({url: longURL});
										});
									} else {
										res.json({url: shortURL});
									}
								} else {
									console.log("Error: ", err);
									res.send("Failure", putRes.statusCode);
								}
							}
					});
				};
				if (!fields.cropImage) {
					uploadToAmazon(file.path);
				} else {
					// Crop the image
					cropPath = "/tmp/" + fileName;
					easyimage.crop({
						src: file.path,
						dst: cropPath,
						cropwidth: fields["crop[width]"],
						cropheight: fields["crop[height]"],
						x: fields["crop[x]"],
						y: fields["crop[y]"],
						gravity: "NorthWest"
					}, function() {
						fs.unlink(file.path);
						uploadToAmazon(cropPath);
					});
				}
				
			} else {
				res.send("Missing file", 500);
			}
		});
		form.on("fileBegin", function(name, file) {
			incomingFiles.push(file);
		});
		form.on("aborted", function() {
			// Remove temporary files that were in the process of uploading
			for (var i = 0; i < incomingFiles.length; i++) {
				fs.unlink(incomingFiles[i].path);
			}
		});
	} else {
		console.log("Missing Amazon S3 credentials (/auth/amazon.js)");
		res.send("Missing Amazon S3 credentials", 500);
	}
};
