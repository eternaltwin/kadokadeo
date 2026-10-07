// Tests of the archive of the game versions: node --test resources/js/games/builds/archive.test.mjs
// (deploys of a fake game "zoo" in a temporary folder: bundles, spritesheets replaced, versions kept or removed)
import assert from 'node:assert/strict'
import { existsSync, mkdirSync, mkdtempSync, readFileSync, rmSync, writeFileSync } from 'node:fs'
import { tmpdir } from 'node:os'
import { join } from 'node:path'
import { test } from 'node:test'
import { gunzipSync } from 'node:zlib'

import { openArchive } from './archive.mjs'
import { applyDelta, bundleHash, makeDelta } from './delta.mjs'
import { decodePng, encodePng } from './png.mjs'

const KEY = 'zoo'

function bundle(v) {
  const lines = Array.from({ length: 300 }, (_, i) => `function f${i}(e) { return e * ${i % 9} } // ${i % 13}`)
  return Buffer.from(`(function () {\n${lines.join('\n')}\nwindow.GameZoo = { v: '${v}' }\n})()\n`)
}

// a spritesheet: frames { name: [w, h, rgba colour] } in one row
function writeSheet(root, frames) {
  const dir = join(root, 'public/assets/img/content', KEY)
  rmSync(dir, { recursive: true, force: true })
  mkdirSync(dir, { recursive: true })
  const names = Object.keys(frames)
  const width = names.reduce((s, n) => s + frames[n][0] + 1, 1)
  const height = Math.max(...names.map((n) => frames[n][1])) + 2
  const data = Buffer.alloc(width * height * 4)
  const json = { frames: {}, animations: { all: names }, meta: { image: `${KEY}-0.png`, scale: '1' } }
  let x = 1
  for (const n of names) {
    const [w, h, c] = frames[n]
    for (let yy = 0; yy < h; yy++) for (let xx = 0; xx < w; xx++) data.writeUInt32BE(c, ((1 + yy) * width + x + xx) * 4)
    json.frames[n] = {
      frame: { x, y: 1, w, h },
      rotated: false,
      trimmed: false,
      spriteSourceSize: { x: 0, y: 0, w, h },
      sourceSize: { w, h },
      anchor: { x: 0.5, y: 0.5 },
    }
    x += w + 1
  }
  writeFileSync(join(dir, `${KEY}-0.png`), encodePng(width, height, data))
  writeFileSync(join(dir, `${KEY}-0.json`), JSON.stringify(json))
}

async function deploy(root, b, { keep, format } = {}) {
  const out = join(root, 'public/gamesdata')
  mkdirSync(out, { recursive: true })
  if (keep) writeFileSync(join(root, 'storage/keep.json'), JSON.stringify(keep))
  const archive = await openArchive({
    storageDir: join(root, 'storage'),
    publicDir: join(out, 'builds'),
    contentDir: join(root, 'public/assets/img/content'),
  })
  const file = join(out, `${KEY}.js`)
  await archive.addBundle(KEY, b, existsSync(file) ? readFileSync(file) : null, format ? { format } : undefined)
  writeFileSync(file, b)
  await archive.finish()
  return JSON.parse(readFileSync(join(root, 'storage/index.json'), 'utf8')).games[KEY]
}

function rebuild(root, g, v) {
  const info = g.versions[v]
  const delta = readFileSync(join(root, 'storage', KEY, 'bundles', `${v}.${info.base}.kdd`))
  return applyDelta(readFileSync(join(root, 'public/gamesdata', `${KEY}.js`)), delta)
}

function versionSheet(root, v) {
  const dir = join(root, 'public/gamesdata/builds', KEY, v)
  const main = JSON.parse(readFileSync(join(dir, `${KEY}-0.json`), 'utf8'))
  const frames = { ...main.frames }
  const image = {}
  for (const n of Object.keys(main.frames)) image[n] = main.meta.image
  for (const f of main.meta.related_multi_packs ?? []) {
    const j = JSON.parse(readFileSync(join(dir, f), 'utf8'))
    Object.assign(frames, j.frames)
    for (const n of Object.keys(j.frames)) image[n] = j.meta.image
  }
  return { main, frames, image }
}

test('delta: an old version is rebuilt byte for byte, from its base only', () => {
  const a = bundle('a')
  const b = bundle('b')
  const d = makeDelta(b, a)
  assert.ok(d.length < 200, `delta of ${d.length} bytes`)
  assert.deepEqual(applyDelta(b, d), a)
  assert.throws(() => applyDelta(a, d), /base/)
})

test('png: what is written is read back', () => {
  const data = Buffer.alloc(7 * 5 * 4)
  for (let i = 0; i < data.length; i++) data[i] = (i * 37) & 0xff
  const img = decodePng(encodePng(7, 5, data))
  assert.equal(img.width, 7)
  assert.deepEqual(img.data, data)
})

test('format of the bundles: the versions archived keep theirs (classic script before the ES modules)', async () => {
  const root = mkdtempSync(join(tmpdir(), 'kado-builds-'))
  try {
    const [v1, v2, v3] = ['v1', 'v2', 'v3'].map(bundle)
    writeSheet(root, { a: [4, 4, 0xff0000ff] })
    let g = await deploy(root, v1)
    assert.equal(g.current.format, 'iife')
    g = await deploy(root, v2, { format: 'esm' })
    assert.equal(g.current.format, 'esm')
    assert.equal(g.versions[bundleHash(v1)].format, 'iife')
    g = await deploy(root, v3, { format: 'esm' })
    assert.equal(g.versions[bundleHash(v1)].format, 'iife')
    assert.equal(g.versions[bundleHash(v2)].format, 'esm')
  } finally {
    rmSync(root, { recursive: true, force: true })
  }
})

test('deploys: versions, spritesheets of the old versions, return to an old version, removal', async () => {
  const root = mkdtempSync(join(tmpdir(), 'kado-builds-'))
  try {
    const [v0, v1, v2, v3] = ['v0', 'v1', 'v2', 'v3'].map(bundle)
    const red = 0xff0000ff
    const green = 0x00ff00ff
    const blue = 0x0000ffff

    // deploy 0: a bundle built before the archive (on disk), then the first build with it
    mkdirSync(join(root, 'public/gamesdata'), { recursive: true })
    writeFileSync(join(root, 'public/gamesdata', `${KEY}.js`), v0)
    writeSheet(root, { a: [4, 4, red], b: [3, 2, green] })
    let g = await deploy(root, v1)
    assert.equal(g.current.hash, bundleHash(v1))
    assert.equal(g.versions[bundleHash(v0)].legacy, true)
    assert.deepEqual(rebuild(root, g, bundleHash(v0)), v0)

    // deploy 2: frame b removed, frame a redrawn (same size), frame c added
    writeSheet(root, { a: [4, 4, blue], c: [5, 5, red] })
    g = await deploy(root, v2)
    const h1 = bundleHash(v1)
    assert.deepEqual(rebuild(root, g, h1), v1)
    assert.deepEqual(rebuild(root, g, bundleHash(v0)), v0)
    assert.equal(g.atlases.length, 1)
    const record = JSON.parse(gunzipSync(readFileSync(join(root, 'storage', KEY, 'atlases', `${g.atlases[0]}.json.gz`))))
    assert.deepEqual(Object.keys(record.captured), ['b'], 'only the frame lost by the new sheet is kept')
    let s = versionSheet(root, h1)
    assert.deepEqual(Object.keys(s.frames).sort(), ['a', 'b'], 'the frames of v1, not c')
    assert.equal(s.image.a, `/assets/img/content/${KEY}/${KEY}-0.png`, 'a: same geometry, the sheet of today')
    assert.equal(s.image.b, `/gamesdata/builds/${KEY}/atlas-${g.atlases[0]}.png`, 'b: from the patch sheet')
    assert.deepEqual(s.main.animations, { all: ['a', 'b'] })
    assert.equal(g.versions[h1].assetBase, `/gamesdata/builds/${KEY}/${h1}/`)
    const patch = decodePng(readFileSync(join(root, 'public/gamesdata/builds', KEY, `atlas-${g.atlases[0]}.png`)))
    const fb = record.captured.b.frame
    assert.equal(patch.data.readUInt32BE((fb.y * patch.width + fb.x) * 4), green, 'the pixels of the old frame b')

    // deploy 3: frame a drawn bigger -> v1 and v2 take the old a from the patch of the sheet of v2
    writeSheet(root, { a: [6, 6, blue], c: [5, 5, red] })
    g = await deploy(root, v3)
    assert.equal(g.atlases.length, 2)
    s = versionSheet(root, h1)
    assert.equal(s.image.a, `/gamesdata/builds/${KEY}/atlas-${g.atlases[1]}.png`)
    assert.equal(s.frames.a.frame.w, 4)
    const h2 = bundleHash(v2)
    s = versionSheet(root, h2)
    assert.deepEqual(Object.keys(s.frames).sort(), ['a', 'c'])
    assert.equal(s.image.c, `/assets/img/content/${KEY}/${KEY}-0.png`)

    // back to v2 (a rollback): it is the current version again, v3 is kept
    g = await deploy(root, v2)
    assert.equal(g.current.hash, h2)
    assert.equal(g.versions[h2], undefined)
    assert.deepEqual(rebuild(root, g, bundleHash(v3)), v3)

    // keep.json written 3 days later: only v1 is used by replays (and the replays recorded before the archive)
    const later = new Date(Date.now() + 3 * 24 * 3600 * 1000).toISOString()
    g = await deploy(root, v2, { keep: { generatedAt: later, games: { [KEY]: [h1] }, legacy: { [KEY]: true } } })
    assert.deepEqual(Object.keys(g.versions).sort(), [bundleHash(v0), h1].sort())
    assert.deepEqual(rebuild(root, g, h1), v1)
    rmSync(join(root, 'storage/keep.json'))

    // the bundle of today lost (public/gamesdata wiped): the copy of the archive is used
    rmSync(join(root, 'public/gamesdata'), { recursive: true, force: true })
    g = await deploy(root, v3)
    assert.deepEqual(rebuild(root, g, h1), v1)
    assert.deepEqual(rebuild(root, g, h2), v2)
  } finally {
    rmSync(root, { recursive: true, force: true })
  }
})
