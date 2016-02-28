var webpack = require("webpack");

module.exports = {
	entry: {
    "test/client": "./test/client.imba"
  },

  output: {
    filename: '[name].js'
  },

  module: {
    loaders: [{ test: /\.imba$/, loader: 'imba/loader' }]
  },

  resolve: {
    extensions: ['', '.imba', '.js']
  },

  node: {
    fs: 'empty'
  }
};