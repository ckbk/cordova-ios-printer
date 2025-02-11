var exec = require('cordova/exec');

exports.print = function (html, success, error) {
    exec(success, error, 'IosPrinter', 'print', [html]);
};
