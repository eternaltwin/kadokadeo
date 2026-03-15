import { mkdir, readdir, unlink } from 'node:fs/promises'
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
}

// delete all tmp*.js
const tmpFiles = (await readdir(sourceDir)).filter((fileName) => fileName.startsWith('tmp') && fileName.endsWith('.js'))
for (const tmpFile of tmpFiles) {
  await unlink(join(sourceDir, tmpFile))
}
