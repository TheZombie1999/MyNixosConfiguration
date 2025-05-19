const builder = require('electron-builder')
const packageFile = require('./../package.json')
const version = packageFile.version
const Platform = builder.Platform
const Arch = builder.Arch

require('./createPackage.js')('linux', {arch: Arch.x64}).then(function (path) {
  const options = {
    linux: {
      target: ['dir'], // change from AppImage to raw output
      icon: 'icons/icon256.png',
      category: 'Network',
      packageCategory: 'Network',
      mimeTypes: ['x-scheme-handler/http', 'x-scheme-handler/https', 'text/html'],
      synopsis: 'Min is a fast, minimal browser that protects your privacy.',
      description: 'A web browser with smarter search...',
      maintainer: 'Min Developers <280953907a@zoho.com>',
    },
    directories: {
      output: 'bin'
    },
    publish: null
  }

  builder.build({
    prepackaged: path,
    targets: Platform.LINUX.createTarget(['dir'], Arch.x64), // updated here too
    config: options
  })
})
