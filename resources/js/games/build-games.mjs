import { createHash } from 'node:crypto'
import { existsSync } from 'node:fs'
import { mkdir, readdir, readFile, unlink, writeFile } from 'node:fs/promises'
import { basename, join } from 'node:path'

import { build } from 'esbuild'

import { openArchive } from './builds/archive.mjs'

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

// old versions of the games kept for their replays (resources/js/games/builds/archive.mjs); GAME_BUILDS=off: none
const archive =
  process.env.GAME_BUILDS === 'off'
    ? null
    : await openArchive({
        storageDir: 'storage/app/game-builds',
        publicDir: join(outputDir, 'builds'),
        contentDir: 'public/assets/img/content',
      })

for (const game of games) {
  const result = await build({
    entryPoints: [game.entry],
    outfile: game.output,
    bundle: true,
    platform: 'browser',
    format: 'iife',
    target: 'es2018',
    sourcemap: true,
    logLevel: 'info',
    write: false,
  })

  // the new bundle is archived before it replaces the previous one on disk
  const bundle = result.outputFiles.find((f) => f.path.endsWith('.js'))
  const outputBuffer = Buffer.from(bundle.contents)
  if (archive) {
    const previous = existsSync(game.output) ? await readFile(game.output) : null
    await archive.addBundle(basename(game.output, '.js'), outputBuffer, previous)
  }
  for (const file of result.outputFiles) await writeFile(file.path, file.contents)
  const hash = createHash('sha1').update(outputBuffer).digest('hex').slice(0, 12)

  manifest[basename(game.output)] = {
    hash,
    size: outputBuffer.byteLength,
  }
}

await writeFile(join(outputDir, 'manifest.json'), `${JSON.stringify(manifest, null, 2)}\n`)

if (archive) await archive.finish()

// delete all tmp*.js
const tmpFiles = (await readdir(sourceDir)).filter(
  (fileName) => fileName.startsWith('tmp') && fileName.endsWith('.js'),
)
for (const tmpFile of tmpFiles) {
  await unlink(join(sourceDir, tmpFile))
}
