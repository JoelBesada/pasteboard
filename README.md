# Pasteboard
Pasteboard is my upcoming web app for easy image uploading. Pasteboard will be replacing [PasteShack](http://www.pasteshack.net) once it's done and will be available at [http://pasteboard.co](http://pasteboard.co).

To try out a preview version that is running the code from the dev branch, visit [http://dev.pasteboard.co](http://dev.pasteboard.co). Please note that any images you upload before the final release might be deleted by me at random.

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
__Step 3 (Optional):__ Edit the example files in the _/auth_ folder with your credentials and rename them according to
the instructions inside the files. You can still run the app without doing this, but certain functions will be missing.