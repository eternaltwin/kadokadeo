// Spritesheets of the old versions of a game.
//
// An old version shows its frames with the spritesheet of today plus a small "patch" sheet: when a spritesheet is
// replaced, only its frames that the new one lacks or draws with another size / trim / anchor are cut out and kept
// (a few KB). A frame drawn again with the same geometry (other colours...) is shown with the new pixels: it does not
// change the game (the code only sees sizes and anchors), and old replays get the graphic fixes.
import { createHash } from 'node:crypto'

import { decodePng, encodePng } from './png.mjs'

const PAD = 1

export function gitBlobId(buffer) {
  return createHash('sha1').update(`blob ${buffer.length}\0`).update(buffer).digest('hex')
}

// the files of the spritesheet of a game: <key>-<n>.json / <key>-<n>.png
export function atlasFileNames(names, key) {
  const re = new RegExp(`^${key}-\\d+\\.(json|png)$`)
  return names.filter((n) => re.test(n)).sort()
}

export function atlasHash(files) {
  const h = createHash('sha1')
  for (const f of files) h.update(`${f.name}\0${f.blob}\n`)
  return h.digest('hex').slice(0, 12)
}

// packs of a spritesheet: [{ name, image, meta, frames }], with a name -> { pack, entry } index
export function readAtlas(jsonFiles) {
  const packs = []
  const index = new Map()
  const animations = {}
  for (const [name, buffer] of jsonFiles) {
    const json = JSON.parse(buffer.toString('utf8'))
    const frames = json.frames ?? {}
    const pack = { name, image: json.meta?.image ?? name.replace(/\.json$/, '.png'), meta: json.meta ?? {}, frames }
    packs.push(pack)
    for (const [frame, entry] of Object.entries(frames)) index.set(frame, { pack, entry })
    Object.assign(animations, json.animations ?? {})
  }
  return { packs, index, animations }
}

// what the game sees of a frame: its size, trim and anchor (not where it is in the sheet)
function geometry(e) {
  const s = e.spriteSourceSize ?? {}
  const o = e.sourceSize ?? {}
  return JSON.stringify([
    e.frame?.w, e.frame?.h, e.trimmed ?? false, s.x, s.y, s.w, s.h, o.w, o.h,
    e.anchor?.x, e.anchor?.y, e.pivot?.x, e.pivot?.y,
  ])
}

function cut(png, entry) {
  const r = entry.frame
  const w = entry.rotated ? r.h : r.w
  const h = entry.rotated ? r.w : r.h
  const data = Buffer.alloc(w * h * 4)
  for (let y = 0; y < h; y++) png.data.copy(data, y * w * 4, ((r.y + y) * png.width + r.x) * 4, ((r.y + y) * png.width + r.x + w) * 4)
  return { w, h, data }
}

// shelves, highest first, PAD transparent pixels between frames (no bleeding with linear filtering)
function pack(items) {
  const width = Math.max(256, ...items.map((i) => i.img.w + 2 * PAD))
  const sorted = [...items].sort((a, b) => b.img.h - a.img.h)
  let x = PAD
  let y = PAD
  let shelf = 0
  for (const it of sorted) {
    if (x + it.img.w + PAD > width) {
      x = PAD
      y += shelf + PAD
      shelf = 0
    }
    it.x = x
    it.y = y
    x += it.img.w + PAD
    shelf = Math.max(shelf, it.img.h)
  }
  const height = y + shelf + PAD
  const data = Buffer.alloc(width * height * 4)
  for (const it of sorted)
    for (let r = 0; r < it.img.h; r++) it.img.data.copy(data, ((it.y + r) * width + it.x) * 4, r * it.img.w * 4, (r + 1) * it.img.w * 4)
  return encodePng(width, height, data)
}

// a spritesheet replaced by a new one: its frame tables, and its frames that the new one cannot show (cut out of its
// PNGs into a patch sheet). pngs: image name -> PNG buffer of the old sheet (null: not available any more)
export function retireAtlas(hash, oldJsonFiles, oldPngs, current) {
  const old = readAtlas(oldJsonFiles)
  const record = {
    hash,
    packs: old.packs.map((p) => ({ name: p.name, image: p.image, meta: stripMeta(p.meta), frames: p.frames })),
    animations: old.animations,
    captured: {},
    patch: false,
    failed: false,
  }
  const need = []
  for (const [name, { pack: p, entry }] of old.index) {
    const now = current.index.get(name)
    if (!now || geometry(now.entry) !== geometry(entry)) need.push({ name, image: p.image, entry })
  }
  if (!need.length) return { record, patch: null }
  const decoded = new Map()
  try {
    for (const n of need) {
      if (!decoded.has(n.image)) {
        const buffer = oldPngs.get(n.image)
        if (!buffer) throw new Error(`${n.image} is not available any more`)
        decoded.set(n.image, decodePng(buffer))
      }
      n.img = cut(decoded.get(n.image), n.entry)
    }
  } catch (e) {
    record.failed = String(e.message ?? e)
    return { record, patch: null }
  }
  const patch = pack(need)
  for (const n of need) {
    const e = structuredClone(n.entry)
    e.frame = { x: n.x, y: n.y, w: n.entry.frame.w, h: n.entry.frame.h }
    record.captured[n.name] = e
  }
  record.patch = true
  return { record, patch }
}

function stripMeta(meta) {
  const m = { ...meta }
  delete m.image
  delete m.related_multi_packs
  delete m.size
  return m
}

// the JSON files of the spritesheet of an old version: its own frame names / geometry, each frame from the newest
// sheet that still draws it the same way (a patch of a retired sheet, or the sheet of today)
//   chain: retired sheets, oldest first; the version's sheet is chain[start]
//   urls: { current(packImage) -> url, patch(hash) -> url }
export function versionAtlasFiles(key, chain, start, current, urls) {
  const own = chain[start]
  const groups = new Map()
  let missing = 0
  const usedPatches = new Set()
  for (const p of own.packs) {
    for (const [name, entry] of Object.entries(p.frames)) {
      let source = null
      for (let i = start; i < chain.length && !source; i++) {
        const c = chain[i].captured[name]
        if (c) {
          source = { key: `p${chain[i].hash}`, url: urls.patch(chain[i].hash), entry: c }
          usedPatches.add(chain[i].hash)
        }
      }
      if (!source) {
        const now = current.index.get(name)
        if (now) source = { key: `c${now.pack.image}`, url: urls.current(now.pack.image), entry: now.entry }
      }
      if (!source) {
        missing++
        continue
      }
      if (!groups.has(source.key)) groups.set(source.key, { url: source.url, frames: {} })
      groups.get(source.key).frames[name] = source.entry ?? entry
    }
  }
  const meta = own.packs[0]?.meta ?? {}
  const list = [...groups.values()]
  const files = list.map((g, i) => ({
    name: i === 0 ? `${key}-0.json` : `${key}-0-${i}.json`,
    json: { frames: g.frames, meta: { ...meta, image: g.url } },
  }))
  if (!files.length) files.push({ name: `${key}-0.json`, json: { frames: {}, meta: { ...meta } } })
  files[0].json.animations = own.animations
  if (files.length > 1) files[0].json.meta.related_multi_packs = files.slice(1).map((f) => f.name)
  return { files, missing, usedPatches }
}
