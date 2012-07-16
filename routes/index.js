var knox = require("knox"),
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
		dataURL = req.body.url.replace(/^data:image\/\w+;base64,/, ""),
		buffer = new Buffer(dataURL,'base64');

		putReq = knoxClient.put("/images/rm_" + microtime.now() + ".png", {
			"Content-Length": buffer.length,
			"Content-Type": "image/png"
		});

		putReq.on("response", function(putRes) {
			if (putRes.statusCode === 200) {
				console.log('saved to %s', putReq.url);
				res.json({url: putReq.url});
			} else {
				console.log('error %d', putReq.statusCode);
				res.send("Failure", putReq.statusCode);
			}
		}).end(buffer);

	} else {
		res.send("Missing Amazon S3 credentials", 500);
	}
};
