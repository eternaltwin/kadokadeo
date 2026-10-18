// node run.cjs <seed> <count> [first depth] | --wells <seeds> <count>: hfgen.js (build.sh) with stubs of the browser
const { join } = require('node:path')
const stub = () => new Proxy(function () {}, { get: (t, k) => (k === 'prototype' ? {} : k in t ? t[k] : (t[k] = stub())), construct: () => stub(), apply: () => stub() })
globalThis.PIXI = new Proxy({}, { get: (t, k) => t[k] || (t[k] = class {}) })
globalThis.window = globalThis
globalThis.document = stub()
globalThis.navigator = { userAgent: 'node' }
require(join(process.env.KKP_WORK || join(require('node:os').homedir(), 'kadokadeo-port'), 'build', 'hfgen.js'))
