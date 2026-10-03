// Minimal PNG reader / writer (RGBA 8 bits) to cut frames out of the spritesheets, without any dependency.
// Reads 8-bit greyscale, RGB, palette, grey+alpha and RGBA images, non interlaced (all the sheets of KadoKadeo are
// RGBA 8 bits); writes RGBA 8 bits.
import { deflateSync, inflateSync } from 'node:zlib'

const SIGNATURE = Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a])

const CRC_TABLE = (() => {
  const t = new Uint32Array(256)
  for (let n = 0; n < 256; n++) {
    let c = n
    for (let k = 0; k < 8; k++) c = c & 1 ? 0xedb88320 ^ (c >>> 1) : c >>> 1
    t[n] = c >>> 0
  }
  return t
})()

function crc32(buf) {
  let c = 0xffffffff
  for (let i = 0; i < buf.length; i++) c = CRC_TABLE[(c ^ buf[i]) & 0xff] ^ (c >>> 8)
  return (c ^ 0xffffffff) >>> 0
}

function paeth(a, b, c) {
  const p = a + b - c
  const pa = Math.abs(p - a)
  const pb = Math.abs(p - b)
  const pc = Math.abs(p - c)
  return pa <= pb && pa <= pc ? a : pb <= pc ? b : c
}

export function decodePng(buf) {
  if (!buf.subarray(0, 8).equals(SIGNATURE)) throw new Error('png: not a PNG file')
  let p = 8
  let width = 0
  let height = 0
  let depth = 0
  let type = 0
  let interlace = 0
  let palette = null
  let trns = null
  const idat = []
  while (p < buf.length) {
    const len = buf.readUInt32BE(p)
    const name = buf.toString('latin1', p + 4, p + 8)
    const data = buf.subarray(p + 8, p + 8 + len)
    if (name === 'IHDR') {
      width = data.readUInt32BE(0)
      height = data.readUInt32BE(4)
      depth = data[8]
      type = data[9]
      interlace = data[12]
    } else if (name === 'PLTE') palette = data
    else if (name === 'tRNS') trns = data
    else if (name === 'IDAT') idat.push(data)
    else if (name === 'IEND') break
    p += 12 + len
  }
  if (depth !== 8 || interlace !== 0) throw new Error(`png: depth ${depth} / interlace ${interlace} not supported`)
  const channels = { 0: 1, 2: 3, 3: 1, 4: 2, 6: 4 }[type]
  if (!channels) throw new Error(`png: colour type ${type} not supported`)
  const raw = inflateSync(Buffer.concat(idat))
  const stride = width * channels
  const pixels = Buffer.alloc(stride * height)
  for (let y = 0; y < height; y++) {
    const filter = raw[y * (stride + 1)]
    const src = y * (stride + 1) + 1
    const dst = y * stride
    for (let x = 0; x < stride; x++) {
      const v = raw[src + x]
      const a = x >= channels ? pixels[dst + x - channels] : 0
      const b = y > 0 ? pixels[dst - stride + x] : 0
      const c = x >= channels && y > 0 ? pixels[dst - stride + x - channels] : 0
      let r
      switch (filter) {
        case 0: r = v; break
        case 1: r = v + a; break
        case 2: r = v + b; break
        case 3: r = v + ((a + b) >> 1); break
        case 4: r = v + paeth(a, b, c); break
        default: throw new Error(`png: bad filter ${filter}`)
      }
      pixels[dst + x] = r & 0xff
    }
  }
  if (type === 6) return { width, height, data: pixels }
  const rgba = Buffer.alloc(width * height * 4)
  for (let i = 0; i < width * height; i++) {
    let r, g, b, a = 255
    if (type === 0) {
      r = g = b = pixels[i]
      if (trns && trns.length >= 2 && trns.readUInt16BE(0) === r) a = 0
    } else if (type === 4) {
      r = g = b = pixels[i * 2]
      a = pixels[i * 2 + 1]
    } else if (type === 2) {
      r = pixels[i * 3]
      g = pixels[i * 3 + 1]
      b = pixels[i * 3 + 2]
      if (trns && trns.length >= 6 && trns.readUInt16BE(0) === r && trns.readUInt16BE(2) === g && trns.readUInt16BE(4) === b) a = 0
    } else {
      const k = pixels[i]
      r = palette[k * 3]
      g = palette[k * 3 + 1]
      b = palette[k * 3 + 2]
      if (trns && k < trns.length) a = trns[k]
    }
    rgba[i * 4] = r
    rgba[i * 4 + 1] = g
    rgba[i * 4 + 2] = b
    rgba[i * 4 + 3] = a
  }
  return { width, height, data: rgba }
}

function chunk(name, data) {
  const head = Buffer.alloc(8)
  head.writeUInt32BE(data.length, 0)
  head.write(name, 4, 'latin1')
  const crc = Buffer.alloc(4)
  crc.writeUInt32BE(crc32(Buffer.concat([head.subarray(4), data])), 0)
  return Buffer.concat([head, data, crc])
}

// RGBA 8 bits, the filter of each row chosen by the smallest sum of absolute values (the usual heuristic)
export function encodePng(width, height, rgba) {
  const stride = width * 4
  const out = Buffer.alloc((stride + 1) * height)
  const row = Buffer.alloc(stride)
  for (let y = 0; y < height; y++) {
    let best = null
    let bestSum = Infinity
    let bestFilter = 0
    for (let f = 0; f < 5; f++) {
      let sum = 0
      for (let x = 0; x < stride; x++) {
        const v = rgba[y * stride + x]
        const a = x >= 4 ? rgba[y * stride + x - 4] : 0
        const b = y > 0 ? rgba[(y - 1) * stride + x] : 0
        const c = x >= 4 && y > 0 ? rgba[(y - 1) * stride + x - 4] : 0
        const pred = f === 0 ? 0 : f === 1 ? a : f === 2 ? b : f === 3 ? (a + b) >> 1 : paeth(a, b, c)
        const r = (v - pred) & 0xff
        row[x] = r
        sum += r < 128 ? r : 256 - r
      }
      if (sum < bestSum) {
        bestSum = sum
        bestFilter = f
        best = Buffer.from(row)
      }
    }
    out[y * (stride + 1)] = bestFilter
    best.copy(out, y * (stride + 1) + 1)
  }
  const ihdr = Buffer.alloc(13)
  ihdr.writeUInt32BE(width, 0)
  ihdr.writeUInt32BE(height, 4)
  ihdr[8] = 8
  ihdr[9] = 6
  return Buffer.concat([
    SIGNATURE,
    chunk('IHDR', ihdr),
    chunk('IDAT', deflateSync(out, { level: 9 })),
    chunk('IEND', Buffer.alloc(0)),
  ])
}
