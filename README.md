# Pasteboard
Pasteboard is my redesigned and renamed update to PasteShack, a web app for easy image uploading. The live version is available at [http://pasteboard.co](http://pasteboard.co), and a development version that's running the code from the dev branch is up at [http://dev.pasteboard.co](http://dev.pasteboard.co).

Chrome extension repo: [https://github.com/JoelBesada/pasteboard-extension](https://github.com/JoelBesada/pasteboard-extension)

MIT Licensed (http://www.opensource.org/licenses/mit-license.php)
Copyright 2012, Joel Besada

## Why this is open source
While future plans for Pasteboard might prevent me from keeping it open source, I've decided to share
the code for now for people to learn from. I'm also hoping that there are developers out there
who would like to contribute to the project by helping out with fixing bugs and adding / discussing new features.

I've provided instructions on how to set up your own copy of the app, but this is mainly to allow people
to fiddle around with the code and test it locally. Please don't publically host a copy of the app in an effort
to drive traffic to your site instead of mine for the exact same functionality. In other words, don't be a jerk.

## Running Locally
Here are the instructions for running the app for local testing:

__Step 1:__ Install [Node](http://nodejs.org/) and [Node Package Manager](https://npmjs.org/).  
__Step 2:__ Run the following commands in the terminal  
```
git clone https://github.com/JoelBesada/pasteboard.git
cd pasteboard
git checkout dev
npm install
sudo apt-get install imagemagick
./run_local
```
__Step 3 (Optional):__ Edit the example files in the _/auth_ folder with your credentials and rename them according to
the instructions inside the files. You can still run the app without doing this, but certain functions will be missing.
