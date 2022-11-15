const esbuild = require('esbuild')

const args = process.argv.slice(2)
const watch = args.includes('--watch')
const deploy = args.includes('--deploy')

// import { sassPlugin } from "esbuild-sass-plugin";
const { sassPlugin } = require("esbuild-sass-plugin");

const isProd = process.argv[2] === 'prod'

const loader = {
  // Add loaders for images/fonts/etc, e.g. { '.svg': 'file' }
}

const plugins = [
  // Add and configure plugins here
  sassPlugin({
    cache: true
  })
]

let opts = {
  entryPoints: ['js/app.js'],
  bundle: true,
  target: 'es2018',
  outdir: '../priv/static/assets',
  logLevel: 'info',
  loader,
  plugins,
  minify: !!isProd,
  external: ['*.woff2','*.woff', '*.ttf', '*.otf', '*.eot', '*.svg']
}

if (watch) {
  opts = {
    ...opts,
    watch,
    sourcemap: 'inline'
  }
}

if (deploy) {
  opts = {
    ...opts,
    minify: true
  }
}

const promise = esbuild.build(opts)

if (watch) {
  promise.then(_result => {
    process.stdin.on('close', () => {
      process.exit(0)
    })

    process.stdin.resume()
  })
}
