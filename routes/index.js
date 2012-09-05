var knox = require("knox"),
	formidable = require("formidable"),
	microtime = require("microtime"),
	easyimage = require("easyimage"),
	request = require('request'),
	fs = require('fs'),
	auth = require('../auth'),
  options = require("../options"),
	knoxClient = null,
	FILE_SIZE_LIMIT = 10 * 1024 * 1024; // 10 MB

if (auth.amazon) {
	knoxClient = knox.createClient({
			key: auth.amazon.S3_KEY,
			secret: auth.amazon.S3_SECRET,
			bucket: auth.amazon.S3_BUCKET
		});
} else {
  console.log("Missing Amazon S3 credentials (/auth/amazon.js)");
}

/* GET, home page */
exports.index =  function(req, res) {
	var params = {
		port: req.app.get("port"),
		redirected: false,
		useAnalytics: false,
		trackingCode: ""
	};

	if (!req.app.get('localrun') && auth.google_analytics) {
		params.useAnalytics = true;
		params.trackingCode = req.app.settings.env === "development" ? auth.google_analytics.development : auth.google_analytics.production;
	}
	if (req.cookies.redirected) {
		params.redirected = true;
		res.clearCookie('redirected');
	}
	res.render("index", params);
};

/* GET, handle redirects from pasteshack */
exports.redirected = function(req, res) {
	res.cookie("redirected", true);
	res.redirect('/');
};

/* GET, force an image to download */
exports.download = function(req, res) {
  var imgReq;
	if(knoxClient) {
		imgReq = request("http://" + auth.amazon.S3_BUCKET + ".s3.amazonaws.com/" + auth.amazon.S3_IMAGE_FOLDER + req.params.image);
	} else {
    imgReq = request("http://" + req.headers.host + options.LOCAL_STORAGE_URL + req.params.image);
	}
  res.set("Content-Disposition", "attachment");
  imgReq.pipe(res);
};

/* GET, proxy to external images to avoid cross origin restrictions */
exports.imageproxy = function(req, res) {
  try {
    request(decodeURIComponent(req.params.image)).pipe(res);
  } catch (err) {
    res.send("Failure", 500);
  }
};

/* GET, image display page */
exports.image = function(req, res) {
  var imageURL;
  if(knoxClient) {
		imageURL = "http://" + auth.amazon.S3_BUCKET + ".s3.amazonaws.com/" + auth.amazon.S3_IMAGE_FOLDER + req.params.image;
  } else {
    imageURL = "http://" + req.headers.host + options.LOCAL_STORAGE_URL + req.params.image;
  }
    
	var params = {
		imageName: req.params.image,
		imageURL: imageURL,
		useAnalytics: false,
		trackingCode: ""
	};

	if (!req.app.get('localrun') && auth.google_analytics) {
		params.useAnalytics = true;
		params.trackingCode = req.app.settings.env === "development" ? auth.google_analytics.development : auth.google_analytics.production;
	}
	res.render("image", params);
};

/* GET, returns the short url for the given file name.
 * Assumes a Parse database has been set up with the
 * class short_url with columns fileName and shortURL.
 *
 * TODO: Set correct status codes
 */
exports.shorturl = function(req, res) {
	if (!auth.parse) {
		res.send("Missing Parse.com credentials", 500);
		return;
	}
	if (!req.params.image) {
		res.send("Missing image parameter", 500);
		return;
	}
	query = encodeURIComponent('{"fileName":"' + req.params.image + '"}');
	request({
		method: "GET",
		uri: "https://api.parse.com/1/classes/short_url?where=" + query,
		headers: {
			"X-Parse-Application-Id": auth.parse.APP_ID,
			"X-Parse-REST-API-Key": auth.parse.API_KEY
		}
	}, function(error, response, body) {
		if(!error && response.statusCode === 200) {
			var result = JSON.parse(body).results[0];
			if (result) {
				res.json({url: result.shortURL});
				return;
			}
		}
		res.send("Not found", 500);
	});
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
  var form = new formidable.IncomingForm(),
    incomingFiles = [];

  form.parse(req, function(err, fields, files) {
    var client,
      file,
      fileType,
      fileExt,
      fileName,
      cropPath,
      uploadToAmazon,
      uploadToFS,
      uploadToStore,
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
      longURL = (req.app.get("localrun") ? "http://" + req.headers.host : req.app.get("domain")) + "/" + fileName;


      if(knoxClient) {
        // Start requesting a short URL
        if(auth.bitly && !req.app.get("localrun")) {
          shortURLRequest = request("http://api.bitly.com/v3/shorten?login=" +
              auth.bitly.LOGIN + "&apiKey=" + auth.bitly.API_KEY +
              "&longUrl=" + encodeURIComponent(longURL),
          function(error, response, body){
            var json;
            if (!error && response.statusCode === 200) {
              json = JSON.parse(body);
              if (json.status_code === 200) {
                shortURL = json.data.url;

                // Store the short URL in the Parse.com database
                if (auth.parse) {
                  request({
                    method: "POST",
                    uri: "https://api.parse.com/1/classes/short_url",
                    headers: {
                      "X-Parse-Application-Id": auth.parse.APP_ID,
                      "X-Parse-REST-API-Key": auth.parse.API_KEY
                    },
                    json: {
                      fileName: fileName,
                      shortURL: shortURL
                    }
                  });
                }
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
            "/" + auth.amazon.S3_IMAGE_FOLDER + fileName,
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
                  res.send("Failure", putRes.statusCode);
                }
              }
          });
        };
      }

      uploadToFS = function(sourcePath) {
        var destFile = options.LOCAL_STORAGE_PATH + fileName;
        fs.rename(sourcePath, destFile, function(err) {
          res.json({url: longURL});
        });
      };

      uploadToStore = function(sourcePath) {
        if (knoxClient) {
          uploadToAmazon(sourcePath);
        } else {
          uploadToFS(sourcePath);
        }
      };
      
      if (!fields.cropImage) {
        uploadToStore(file.path);
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
          uploadToStore(cropPath);
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
};
