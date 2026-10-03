// Binary delta of two versions of a game bundle ("KDD1"): the target (an old version) is rebuilt from the base (the
// current version) with "copy these bytes of the base" and "add these new bytes". Two builds of a game differ by a
// few lines, so an old version costs a few hundred bytes instead of ~1 MB. The format is read back by
// app/Support/GameBuilds/BundleDelta.php (keep both in sync).
//
// Layout (then deflated, raw deflate):
//   "KDD1" | base hash (12 ascii hex) | target hash (12 ascii hex) | varint target length
//   then until the target is complete: varint literal length, literal bytes,
//                                      varint copy length, zigzag varint (copy start - end of the previous copy)
import { createHash } from 'node:crypto'
import { deflateRawSync, inflateRawSync } from 'node:zlib'

const MAGIC = 'KDD1'
const BLOCK = 24
const STEP = 4
const MUL = 0x01000193

export function bundleHash(buffer) {
  return createHash('sha1').update(buffer).digest('hex').slice(0, 12)
}

function pushVarint(out, n) {
  while (n >= 0x80) {
    out.push((n & 0x7f) | 0x80)
    n = Math.floor(n / 128)
  }
  out.push(n)
}

function zigzag(n) {
  return n >= 0 ? n * 2 : -n * 2 - 1
}

// polynomial hash of the BLOCK bytes at i
function blockHash(buf, i) {
  let h = 0
  for (let k = 0; k < BLOCK; k++) h = (Math.imul(h, MUL) + buf[i + k]) >>> 0
  return h
}

export function makeDelta(base, target) {
  const baseHash = bundleHash(base)
  const targetHash = bundleHash(target)

  // index of the blocks of the base (every STEP bytes)
  const index = new Map()
  for (let i = 0; i + BLOCK <= base.length; i += STEP) {
    const h = blockHash(base, i)
    if (!index.has(h)) index.set(h, i)
  }

  // rolling hash over the target: h(i + 1) = (h(i) - b[i] * MUL^(BLOCK-1)) * MUL + b[i + BLOCK]
  let top = 1
  for (let k = 0; k < BLOCK - 1; k++) top = Math.imul(top, MUL) >>> 0

  const ops = []
  pushVarint(ops, target.length)
  let litStart = 0
  let expect = 0
  let t = 0
  let h = target.length >= BLOCK ? blockHash(target, 0) : 0
  const n = target.length
  while (t + BLOCK <= n) {
    const j = index.get(h)
    let matched = false
    if (j !== undefined) {
      let k = 0
      while (k < BLOCK && base[j + k] === target[t + k]) k++
      if (k === BLOCK) {
        // extend backwards into the pending literal, then forwards
        let a = t
        let b = j
        while (a > litStart && b > 0 && target[a - 1] === base[b - 1]) {
          a--
          b--
        }
        let e = t + BLOCK
        let f = j + BLOCK
        while (e < n && f < base.length && target[e] === base[f]) {
          e++
          f++
        }
        pushVarint(ops, a - litStart)
        for (let q = litStart; q < a; q++) ops.push(target[q])
        pushVarint(ops, e - a)
        pushVarint(ops, zigzag(b - expect))
        expect = f
        litStart = e
        t = e
        h = t + BLOCK <= n ? blockHash(target, t) : 0
        matched = true
      }
    }
    if (!matched) {
      if (t + BLOCK < n) h = (Math.imul((h - Math.imul(target[t], top)) >>> 0, MUL) + target[t + BLOCK]) >>> 0
      t++
    }
  }
  pushVarint(ops, n - litStart)
  for (let q = litStart; q < n; q++) ops.push(target[q])

  const head = Buffer.from(MAGIC + baseHash + targetHash, 'latin1')
  const raw = Buffer.concat([head, Buffer.from(ops)])
  const delta = deflateRawSync(raw, { level: 9 })

  // never keep a delta that does not give the target back
  const check = applyDelta(base, delta)
  if (!check.equals(target)) throw new Error('delta: the old version cannot be rebuilt')
  return delta
}

export function readDeltaHeader(delta) {
  const raw = inflateRawSync(delta)
  if (raw.toString('latin1', 0, 4) !== MAGIC) throw new Error('delta: bad magic')
  return { baseHash: raw.toString('latin1', 4, 16), targetHash: raw.toString('latin1', 16, 28), raw }
}

export function applyDelta(base, delta) {
  const { baseHash, targetHash, raw } = readDeltaHeader(delta)
  if (bundleHash(base) !== baseHash) throw new Error(`delta: base ${baseHash} expected`)
  let p = 28
  const varint = () => {
    let v = 0
    let s = 1
    for (;;) {
      const c = raw[p++]
      v += (c & 0x7f) * s
      if (c < 0x80) return v
      s *= 128
    }
  }
  const length = varint()
  const out = Buffer.alloc(length)
  let o = 0
  let expect = 0
  while (o < length) {
    const lit = varint()
    raw.copy(out, o, p, p + lit)
    p += lit
    o += lit
    if (o >= length) break
    const len = varint()
    const z = varint()
    const off = expect + (z % 2 === 0 ? z / 2 : -(z + 1) / 2)
    base.copy(out, o, off, off + len)
    o += len
    expect = off + len
  }
  if (bundleHash(out) !== targetHash) throw new Error(`delta: rebuilt version is not ${targetHash}`)
  return out
}
