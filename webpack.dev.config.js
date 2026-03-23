const path = require("path")
const webpack = require("webpack")
const ReactRefreshWebpackPlugin = require("@pmmmwh/react-refresh-webpack-plugin")

module.exports = {
  mode: "development",
  devtool: "cheap-module-source-map",
  entry: {
    notes: "./app/javascript/notes/index.jsx"
  },
  output: {
    filename: "[name].js",
    publicPath: "auto",
  },
  resolve: {
    extensions: [".js", ".jsx"],
  },
  devServer: {
    port: 3035,
    host: "0.0.0.0",
    hot: true,
    headers: {
      "Access-Control-Allow-Origin": "*",
    },
    allowedHosts: "all",
  },
  module: {
    rules: [
      {
        test: /\.jsx?$/,
        exclude: /node_modules/,
        use: {
          loader: "babel-loader",
          options: {
            presets: ["@babel/preset-env", "@babel/preset-react"],
            plugins: [require.resolve("react-refresh/babel")],
          },
        },
      },
    ],
  },
  plugins: [
    new webpack.HotModuleReplacementPlugin(),
    new ReactRefreshWebpackPlugin(),
  ]
}
