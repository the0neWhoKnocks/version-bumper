var path = require('path');

var source = path.resolve(__dirname, './index.js');
var conf = {
  entry: {
    Example: source
  },
  output: {
    filename: '[name].js',
    library: '[name]', // expose exported item to window
    libraryTarget: 'umd',
    path: path.resolve(__dirname, './dist'),
    umdNamedDefine: true
  },
  module: {
    rules: [
      // insert package version into components
      {
        test: /index\.js$/,
        loader: 'string-replace-loader',
        exclude: /node_modules/,
        include: [
          source,
        ],
        query: {
          search: 'COMPONENT_VERSION',
          replace: process.env.npm_package_version,
          flags: 'g'
        }
      }
    ]
  }
};

module.exports = conf;
