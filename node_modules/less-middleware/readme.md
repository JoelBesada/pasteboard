## Installation

    sudo npm install less-middleware

## Options

<table>
    <thead>
        <tr>
            <th>Option</th>
            <th>Description</th>
            <th>Default</th>
        </tr>
    </thead>
    <tbody>
        <tr>
            <th><code>force</code></th>
            <td>Always re-compile less files on each request.</td>
            <td><code>false</code></td>
        </tr>
        <tr>
            <th><code>once</code></th>
            <td>Only check for need to recompile once after each server restart. Useful for reducing disk i/o on production.</td>
            <td><code>false</code></td>
        </tr>
        <tr>
            <th><code>debug</code></th>
            <td>Output any debugging messages to the console.</td>
            <td><code>false</code></td>
        </tr>
        <tr>
            <th><code>src</code></th>
            <td>Source directory containing the <code>.less</code> files. <strong>Required.</strong></td>
            <td></td>
        </tr>
        <tr>
            <th><code>dest</code></th>
            <td>Desitnation directory to output the compiled <code>.css</code> files.</td>
            <td><code>&lt;src&gt;</code></td>
        </tr>
        <tr>
            <th><code>compress</code></th>
            <td>Compress the output being written to the <code>*.css</code> files. When set to <code>'auto'</code> compression will only happen when the css file ends with <code>.min.css</code> or <code>-min.css</code>.</td>
            <td><code>auto</code></td>
        </tr>
        <tr>
            <th><code>optimization</code></th>
            <td>Desired level of LESS optimization. Optionally <code>0</code>, <code>1</code>, or <code>2</code></td>
            <td><code>0</code></td>
        </tr>
    </tbody>
</table>

## Examples

### Connect

    var lessMiddleware = require('less-middleware');

    var server = connect.createServer(
        lessMiddleware({
            src: __dirname + '/public',
            compress: true
        }),
        connect.staticProvider(__dirname + '/public')
    );

### Express

    var lessMiddleware = require('less-middleware');

    var app = express.createServer();

    app.configure(function () {
        // Other configuration here...

        app.use(lessMiddleware({
            src: __dirname + '/public',
            compress: true
        }));

        app.use(express.static(__dirname + '/public'));
    });
