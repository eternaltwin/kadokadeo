// Fixtures of tests/Feature/GameBuildsTest.php: an archive with two old versions of the game "testgame", encoded by
// the delta of the build (node tests/Fixtures/game-builds/make.mjs, from the root of the repository)
import { mkdirSync, writeFileSync } from 'node:fs'
import { gzipSync } from 'node:zlib'
import { bundleHash, makeDelta } from '../../../resources/js/games/builds/delta.mjs'

const dir = 'tests/Fixtures/game-builds'
const lines = (v, speed) =>
  Array.from({ length: 200 }, (_, i) => `function step${i}(e) { e.x += ${speed} * ${i % 7}; return e } // ${v}`).join('\n')
const bundle = (v, speed) => Buffer.from(`(function () {\n${lines(v, speed)}\nwindow.GameTestgame = { version: '${v}' }\n})()\n`)

const current = bundle('v3', 3)
const old = bundle('v2', 2)
const legacy = bundle('v1', 1)
const cur = bundleHash(current)
const h2 = bundleHash(old)
const h1 = bundleHash(legacy)

mkdirSync(`${dir}/public/gamesdata`, { recursive: true })
mkdirSync(`${dir}/storage/testgame/bundles`, { recursive: true })
mkdirSync(`${dir}/expected`, { recursive: true })
writeFileSync(`${dir}/public/gamesdata/testgame.js`, current)
writeFileSync(`${dir}/public/gamesdata/manifest.json`, JSON.stringify({ 'testgame.js': { hash: cur, size: current.length, format: 'esm' } }, null, 2) + '\n')
writeFileSync(`${dir}/storage/testgame/bundles/${h2}.${cur}.kdd`, makeDelta(current, old))
writeFileSync(`${dir}/storage/testgame/bundles/${h1}.${cur}.kdd`, makeDelta(current, legacy))
writeFileSync(`${dir}/storage/testgame/current.js.gz`, gzipSync(current))
writeFileSync(`${dir}/expected/${h2}.js`, old)
writeFileSync(`${dir}/expected/${h1}.js`, legacy)
const index = {
  format: 1,
  games: {
    testgame: {
      current: { hash: cur, atlas: 'aaaaaaaaaaaa', since: '2026-10-03T10:00:00.000Z', format: 'esm' },
      versions: {
        [h1]: { base: cur, atlas: null, assetBase: null, legacy: true, since: null, retiredAt: '2026-10-01T10:00:00.000Z', size: legacy.length },
        [h2]: { base: cur, atlas: 'bbbbbbbbbbbb', assetBase: `/gamesdata/builds/testgame/${h2}/`, legacy: false, since: '2026-10-01T10:00:00.000Z', retiredAt: '2026-10-03T10:00:00.000Z', size: old.length, format: 'esm' },
      },
      atlas: { hash: 'aaaaaaaaaaaa', files: [] },
      atlases: ['bbbbbbbbbbbb'],
    },
  },
}
writeFileSync(`${dir}/storage/index.json`, JSON.stringify(index, null, 1) + '\n')

// a build running: the next bundle is on disk with the delta of the old version for it, the index not written yet
const next = bundle('v4', 4)
mkdirSync(`${dir}/building/public/gamesdata`, { recursive: true })
writeFileSync(`${dir}/building/public/gamesdata/testgame.js`, next)
writeFileSync(`${dir}/storage/testgame/bundles/${h2}.${bundleHash(next)}.kdd`, makeDelta(next, old))
console.log(JSON.stringify({ current: cur, old: h2, legacy: h1 }))
