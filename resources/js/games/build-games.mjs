import { createHash } from 'node:crypto'
import { existsSync } from 'node:fs'
import { mkdir, readdir, readFile, unlink, writeFile } from 'node:fs/promises'
import { basename, join } from 'node:path'

import { openArchive } from './builds/archive.mjs'
import { BUNDLE_FORMAT, bundleGame } from './builds/bundle.mjs'

const sourceDir = 'resources/js/games'
const outputDir = 'public/gamesdata'
// not public: the bundles are minified, their source maps are only for us (crash reports)
const sourceMapDir = 'storage/app/game-sourcemaps'

const games = (await readdir(sourceDir))
  .filter((fileName) => !fileName.startsWith('tmp') && fileName.endsWith('.js'))
  .sort()
  .map((fileName) => ({
    entry: join(sourceDir, fileName),
    output: join(outputDir, basename(fileName)),
  }))

await mkdir(outputDir, { recursive: true })
await mkdir(sourceMapDir, { recursive: true })

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
  const { code, map } = await bundleGame(game.entry)

  // the new bundle is archived before it replaces the previous one on disk
  const outputBuffer = code
  if (archive) {
    const previous = existsSync(game.output) ? await readFile(game.output) : null
    await archive.addBundle(basename(game.output, '.js'), outputBuffer, previous, { format: BUNDLE_FORMAT })
  }
  await writeFile(game.output, code)
  await writeFile(join(sourceMapDir, `${basename(game.output)}.map`), map)
  // source maps published by the builds before
  await unlink(`${game.output}.map`).catch(() => {})
  const hash = createHash('sha1').update(outputBuffer).digest('hex').slice(0, 12)

  manifest[basename(game.output)] = {
    hash,
    size: outputBuffer.byteLength,
    // esm: loaded with import() (builds/bundle.mjs)
    format: BUNDLE_FORMAT,
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
