# Pasteboard
Pasteboard is my upcoming web app for easy image uploading. Pasteboard will be replacing [PasteShack](http://www.pasteshack.net) once it's done.
The final version will be available at [http://pasteboard.me](http://pasteboard.me) (the site lacks any kind of functionality at the moment).   

To try out a preview version that is running the code from the dev branch, visit [http://dev.pasteboard.me](http://dev.pasteboard.me). Please
note that any images you upload before the final release might be deleted at random.

MIT Licensed (http://www.opensource.org/licenses/mit-license.php)   
Copyright 2012, Joel Besada

## Running Locally
__Step 1:__ Install [Node](http://nodejs.org/) and [Node Package Manager](https://npmjs.org/).   
__Step 2:__ Run the following commands in the terminal   
``` 
git clone https://github.com/JoelBesada/pasteboard.git   
cd pasteboard
git checkout dev
npm install
./run_local
```
__Step 3 (Optional):__ Edit _/auth/amazon.example.js_ with your Amazon S3 credentials and rename the file to _amazon.js_.
You can still run the app without this, but the images will not be uploaded anywhere.