// Archive of the versions of the game bundles, so that a replay is played with the version of the game it was
// recorded with (a replay only holds the inputs: another version of the game code plays them differently).
//
// storage/app/game-builds/ (kept between deploys, read by Laravel: app/Support/GameBuilds/GameBuildArchive.php)
//   index.json                     versions of each game (see below)
//   keep.json                      written by `php artisan kado:game-builds:keep`: the versions still used by replays
//   <key>/current.js.gz            a copy of the current bundle (the base of the deltas, if public/ is wiped)
//   <key>/bundles/<v>.<base>.kdd   an old version <v> as a delta of the current bundle <base> (delta.mjs)
//   <key>/atlases/<h>.json.gz      frame tables of a replaced spritesheet <h>, and its frames kept in the patch sheet
//   <key>/atlases/<h>.png          the patch sheet of <h> (only the frames the newer sheet cannot show)
//   <key>/snapshot/                the files of the current spritesheet (hard links: no space) to cut the patch
//                                  sheet out of when it is replaced (or read back from git)
// public/gamesdata/builds/<key>/  (rebuilt at each build, served by nginx)
//   atlas-<h>.png                  patch sheets
//   <v>/<key>-0.json ...           the spritesheet of the old version <v> (frames of today + patch sheets)
// The bundle of an old version is rebuilt by Laravel (route /gamesdata/builds/<key>/<v>.js).
//
// index.json: { format: 1, games: { <key>: {
//   current: { hash, atlas, since, format },      the bundle of today (atlas: hash of its spritesheet)
//   versions: { <v>: { base, atlas, assetBase, legacy, since, retiredAt, size, format } },
//   (format of a bundle: 'esm', an ES module loaded with import(), or 'iife' / missing, a classic script: see bundle.mjs)
//   atlas: { hash, files: [{ name, blob }] },     the spritesheet of today (git blob ids of its files)
//   atlases: [<h>, ...] } } }                     replaced spritesheets, oldest first
import { execFileSync } from 'node:child_process'
import { copyFile, link, mkdir, readdir, readFile, rename, rm, unlink, writeFile } from 'node:fs/promises'
import { existsSync } from 'node:fs'
import { join } from 'node:path'
import { gunzipSync, gzipSync } from 'node:zlib'

import { atlasFileNames, atlasHash, gitBlobId, readAtlas, retireAtlas, versionAtlasFiles } from './atlas.mjs'
import { applyDelta, bundleHash, makeDelta } from './delta.mjs'

// a version still used by a replay is never removed; an unused one only when keep.json is younger than its
// retirement by this margin (players with an old tab open finish their games)
const KEEP_MARGIN_MS = 2 * 24 * 3600 * 1000

const log = (...a) => console.log('[game-builds]', ...a)

export async function openArchive({ storageDir, publicDir, contentDir, publicUrl = '/gamesdata/builds', contentUrl = '/assets/img/content' }) {
  const indexPath = join(storageDir, 'index.json')
  const index = existsSync(indexPath) ? JSON.parse(await readFile(indexPath, 'utf8')) : { format: 1, games: {} }
  const keepPath = join(storageDir, 'keep.json')
  const keep = existsSync(keepPath) ? JSON.parse(await readFile(keepPath, 'utf8')) : null
  const now = new Date().toISOString()
  const deltaFile = (key, v, base) => join(storageDir, key, 'bundles', `${v}.${base}.kdd`)

  function game(key) {
    index.games[key] ??= { current: null, versions: {}, atlas: null, atlases: [] }
    return index.games[key]
  }

  // before the new bundle replaces `previous` on disk: the current version becomes an old one (delta), the old ones
  // are rebased on the new bundle
  async function addBundle(key, bundle, previous, { format = 'iife' } = {}) {
    const g = game(key)
    const hash = bundleHash(bundle)
    const copy = join(storageDir, key, 'current.js.gz')
    if (g.current?.hash === hash) {
      g.current.format = format
      if (!existsSync(copy)) {
        await mkdir(join(storageDir, key), { recursive: true })
        await writeFile(copy, gzipSync(bundle, { level: 9 }))
      }
      return
    }
    let cur = null
    if (g.current) {
      if (previous && bundleHash(previous) === g.current.hash) cur = previous
      else if (existsSync(copy)) {
        const b = gunzipSync(await readFile(copy))
        if (bundleHash(b) === g.current.hash) cur = b
      }
      if (!cur) log(`${key}: the bundle ${g.current.hash} is lost, its old versions are dropped`)
    } else if (previous) {
      // first build with the archive: the bundle found on disk was built before it (replays without a version)
      g.current = { hash: bundleHash(previous), atlas: null, legacy: true, since: null }
      cur = previous
    }
    const versions = {}
    if (cur) {
      await mkdir(join(storageDir, key, 'bundles'), { recursive: true })
      for (const [v, info] of Object.entries(g.versions)) {
        if (v === hash) continue // back to an old version: it is the current one again
        try {
          const old = applyDelta(cur, await readFile(deltaFile(key, v, info.base)))
          await writeFile(deltaFile(key, v, hash), makeDelta(bundle, old))
          versions[v] = { ...info, base: hash, size: old.length }
        } catch (e) {
          log(`${key}: version ${v} dropped (${e.message})`)
        }
      }
      if (g.current.hash !== hash) {
        await writeFile(deltaFile(key, g.current.hash, hash), makeDelta(bundle, cur))
        versions[g.current.hash] = {
          base: hash,
          atlas: g.current.atlas,
          assetBase: null,
          legacy: !!g.current.legacy,
          since: g.current.since,
          retiredAt: now,
          size: cur.length,
          format: g.current.format ?? 'iife',
        }
        log(`${key}: ${g.current.hash} archived (${Object.keys(versions).length} old versions)`)
      }
    }
    g.versions = versions
    g.current = { hash, atlas: null, since: now, format }
    await mkdir(join(storageDir, key), { recursive: true })
    await writeFile(copy, gzipSync(bundle, { level: 9 }))
  }

  async function readSnapshotOrGit(key, file) {
    const p = join(storageDir, key, 'snapshot', file.name)
    if (existsSync(p)) {
      const b = await readFile(p)
      if (gitBlobId(b) === file.blob) return b
    }
    try {
      return execFileSync('git', ['cat-file', 'blob', file.blob], { maxBuffer: 1 << 28, stdio: ['ignore', 'pipe', 'ignore'] })
    } catch {
      return null
    }
  }

  async function snapshot(key, dir, names) {
    const snap = join(storageDir, key, 'snapshot')
    await rm(snap, { recursive: true, force: true })
    await mkdir(snap, { recursive: true })
    for (const n of names) {
      try {
        await link(join(dir, n), join(snap, n))
      } catch {
        await copyFile(join(dir, n), join(snap, n))
      }
    }
  }

  const recordPath = (key, h) => join(storageDir, key, 'atlases', `${h}.json.gz`)
  const patchPath = (key, h) => join(storageDir, key, 'atlases', `${h}.png`)

  async function readRecord(key, h) {
    return JSON.parse(gunzipSync(await readFile(recordPath(key, h))).toString('utf8'))
  }

  // the spritesheet of a game: replaced since the last build -> its record and patch sheet; snapshot of today's
  async function updateAtlas(key) {
    const g = game(key)
    const dir = join(contentDir, key)
    const names = existsSync(dir) ? atlasFileNames(await readdir(dir), key) : []
    if (!names.includes(`${key}-0.json`)) {
      g.atlas = null
      return null
    }
    const files = []
    const buffers = new Map()
    for (const name of names) {
      const b = await readFile(join(dir, name))
      buffers.set(name, b)
      files.push({ name, blob: gitBlobId(b) })
    }
    const hash = atlasHash(files)
    const current = readAtlas(names.filter((n) => n.endsWith('.json')).map((n) => [n, buffers.get(n)]))
    if (g.atlas && g.atlas.hash !== hash && !g.atlases.includes(g.atlas.hash)) {
      const jsons = []
      const pngs = new Map()
      for (const f of g.atlas.files) {
        const b = await readSnapshotOrGit(key, f)
        if (f.name.endsWith('.json')) {
          if (b) jsons.push([f.name, b])
        } else pngs.set(f.name, b)
      }
      if (jsons.length) {
        const { record, patch } = retireAtlas(g.atlas.hash, jsons, pngs, current)
        await mkdir(join(storageDir, key, 'atlases'), { recursive: true })
        await writeFile(recordPath(key, record.hash), gzipSync(JSON.stringify(record), { level: 9 }))
        if (patch) await writeFile(patchPath(key, record.hash), patch)
        g.atlases.push(record.hash)
        const kept = Object.keys(record.captured).length
        log(`${key}: spritesheet ${record.hash} replaced, ${kept} frames kept${patch ? ` (${patch.length} bytes)` : ''}${record.failed ? ` - FAILED: ${record.failed}` : ''}`)
      } else log(`${key}: spritesheet ${g.atlas.hash} replaced but not readable any more (no snapshot, not in git)`)
    }
    if (!g.atlas || g.atlas.hash !== hash) {
      await snapshot(key, dir, names)
      g.atlas = { hash, files }
    }
    if (g.current && !g.current.legacy) g.current.atlas = hash
    return current
  }

  function prune(key) {
    const g = game(key)
    if (!keep?.generatedAt) return
    const at = Date.parse(keep.generatedAt)
    const used = new Set(keep.games?.[key] ?? [])
    const legacyUsed = !!keep.legacy?.[key]
    for (const [v, info] of Object.entries(g.versions)) {
      if (used.has(v) || (info.legacy && legacyUsed)) continue
      if (at - Date.parse(info.retiredAt) < KEEP_MARGIN_MS) continue
      delete g.versions[v]
      log(`${key}: ${v} removed (no replay uses it)`)
    }
  }

  // public files of the old versions: their spritesheet when it is not today's one
  async function publish(key, current) {
    const g = game(key)
    const out = join(publicDir, key)
    await rm(out, { recursive: true, force: true })
    // replaced spritesheets still needed: from the oldest one used by a version up to today
    const chain = g.atlases
    const first = Math.min(...Object.values(g.versions).map((v) => (v.atlas ? chain.indexOf(v.atlas) : Infinity)).filter((i) => i >= 0), chain.length)
    for (const h of chain.slice(0, first)) {
      await rm(recordPath(key, h), { force: true })
      await rm(patchPath(key, h), { force: true })
    }
    g.atlases = chain.slice(first)
    const records = []
    for (const h of g.atlases) records.push(await readRecord(key, h))
    const patches = new Set()
    for (const [v, info] of Object.entries(g.versions)) {
      info.assetBase = null
      const start = info.atlas ? g.atlases.indexOf(info.atlas) : -1
      if (start < 0 || !current) continue
      const { files, missing, usedPatches } = versionAtlasFiles(key, records, start, current, {
        current: (image) => `${contentUrl}/${key}/${image}`,
        patch: (h) => `${publicUrl}/${key}/atlas-${h}.png`,
      })
      await mkdir(join(out, v), { recursive: true })
      for (const f of files) await writeFile(join(out, v, f.name), JSON.stringify(f.json))
      for (const h of usedPatches) patches.add(h)
      info.assetBase = `${publicUrl}/${key}/${v}/`
      if (missing) log(`${key}: version ${v}: ${missing} frames cannot be shown any more`)
    }
    for (const h of patches) {
      try {
        await link(patchPath(key, h), join(out, `atlas-${h}.png`))
      } catch {
        await copyFile(patchPath(key, h), join(out, `atlas-${h}.png`))
      }
    }
  }

  async function cleanBundles(key) {
    const dir = join(storageDir, key, 'bundles')
    if (!existsSync(dir)) return
    const g = game(key)
    const wanted = new Set(Object.entries(g.versions).map(([v, i]) => `${v}.${i.base}.kdd`))
    for (const f of await readdir(dir)) if (!wanted.has(f)) await unlink(join(dir, f))
  }

  async function finish() {
    for (const key of Object.keys(index.games)) {
      const current = await updateAtlas(key)
      prune(key)
      await publish(key, current)
    }
    await mkdir(storageDir, { recursive: true })
    const tmp = `${indexPath}.tmp`
    await writeFile(tmp, `${JSON.stringify(index, null, 1)}\n`)
    await rename(tmp, indexPath)
    for (const key of Object.keys(index.games)) await cleanBundles(key)
    const n = Object.values(index.games).reduce((s, g) => s + Object.keys(g.versions).length, 0)
    log(`${Object.keys(index.games).length} games, ${n} old versions kept`)
  }

  return { addBundle, finish, index }
}
