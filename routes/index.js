var knox = require("knox"),
	formidable = require("formidable"),
	microtime = require("microtime"),
	amazonAuth = require("../auth/amazon.js");

/* GET home page */
exports.index = function(req, res){
	res.render("index", { title: "Pasteboard" });
};

/* POST image upload */
exports.upload = function(req, res){
	if (amazonAuth.S3_KEY && amazonAuth.S3_SECRET && amazonAuth.S3_BUCKET) {
		var knoxClient = knox.createClient({
				key: amazonAuth.S3_KEY,
				secret: amazonAuth.S3_SECRET,
				bucket: amazonAuth.S3_BUCKET
			}),
			fs = require('fs'),
			form = new formidable.IncomingForm(),
			percent = 0;
		
		console.log("Uploading file to server");
		form.parse(req, function(err, fields, files) {
			var type = files.file.type,
				fileExt = type.replace("image/", ""),
				filePath = "/images/rm_" + microtime.now() + "." + (fileExt === "jpeg" ? "jpg" : fileExt);
				
			console.log("Uploading file to Amazon");
			knoxClient.putFile(
				files.file.path,
				filePath,
				{ "Content-Type": type },
				function(err, putRes) {
					var url = "http://pasteboard.s3.amazonaws.com" + filePath;
					fs.unlink(files.file.path);

					if (putRes.statusCode === 200) {
						console.log('saved to %s', url);
						res.json({url: url});
					} else {
						console.log("Error: ", err);
						res.send("Failure", putRes.statusCode);
					}
			});
		});
		form.on("progress", function(rec, tot) {
			if (rec/tot > percent + 0.1) {
				percent += 0.1;
				console.log(percent * 100 + "%");
			}
		});

	} else {
		res.send("Missing Amazon S3 credentials", 500);
	}
};