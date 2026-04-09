import { createHash } from 'node:crypto'
import { mkdir, readdir, readFile, unlink, writeFile } from 'node:fs/promises'
import { basename, join } from 'node:path'

import { build } from 'esbuild'

const sourceDir = 'resources/js/games'
const outputDir = 'public/gamesdata'

const games = (await readdir(sourceDir))
  .filter((fileName) => !fileName.startsWith('tmp') && fileName.endsWith('.js'))
  .sort()
  .map((fileName) => ({
    entry: join(sourceDir, fileName),
    output: join(outputDir, basename(fileName)),
  }))

await mkdir(outputDir, { recursive: true })

const manifest = {}

for (const game of games) {
  await build({
    entryPoints: [game.entry],
    outfile: game.output,
    bundle: true,
    platform: 'browser',
    format: 'iife',
    target: 'es2018',
    sourcemap: true,
    logLevel: 'info',
  })

  const outputBuffer = await readFile(game.output)
  const hash = createHash('sha1').update(outputBuffer).digest('hex').slice(0, 12)

  manifest[basename(game.output)] = {
    hash,
    size: outputBuffer.byteLength,
  }
}

await writeFile(join(outputDir, 'manifest.json'), `${JSON.stringify(manifest, null, 2)}\n`)

// delete all tmp*.js
const tmpFiles = (await readdir(sourceDir)).filter(
  (fileName) => fileName.startsWith('tmp') && fileName.endsWith('.js'),
)
for (const tmpFile of tmpFiles) {
  await unlink(join(sourceDir, tmpFile))
}
