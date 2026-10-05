// Finds the Chrome / Chromium of the replay verifier, in this order:
//   - env BROWSER: its path
//   - a Chrome / Chromium installed on the system, at the usual places
//   - a chrome-headless-shell downloaded in <cacheDir> (package @puppeteer/browsers), downloaded first when asked:
//     for a server where no browser can be installed (only npm packages), the system libraries of Chrome must be there
import { spawnSync } from 'node:child_process'
import { existsSync, mkdirSync, readdirSync, rmSync, statSync, writeFileSync } from 'node:fs'
import { dirname, join } from 'node:path'

const CANDIDATES = {
  darwin: ['/Applications/Google Chrome.app/Contents/MacOS/Google Chrome', '/Applications/Chromium.app/Contents/MacOS/Chromium'],
  linux: ['/usr/bin/chromium', '/usr/bin/chromium-browser', '/usr/bin/google-chrome', '/usr/bin/google-chrome-stable'],
}
const SHELL = 'chrome-headless-shell'
// written in the folder of a build once it is fully extracted (a process killed while extracting leaves half a browser)
const COMPLETE = '.complete'
// a download left by a process that died: given up after that
const LOCK_STALE_MS = 10 * 60 * 1000
const sleep = (ms) => new Promise((r) => setTimeout(r, ms))

// the newest chrome-headless-shell of the cache (<cacheDir>/chrome-headless-shell/<platform>-<build>/<folder>/<binary>)
function downloaded(cacheDir) {
  const root = join(cacheDir, SHELL)
  let builds = []
  try { builds = readdirSync(root) } catch { return null }
  builds.sort((a, b) => b.localeCompare(a, 'en', { numeric: true }))
  for (const build of builds) {
    if (!existsSync(join(root, build, COMPLETE))) continue
    let folders = []
    try { folders = readdirSync(join(root, build)) } catch { continue }
    for (const folder of folders) {
      const path = join(root, build, folder, process.platform === 'win32' ? SHELL + '.exe' : SHELL)
      if (existsSync(path)) return path
    }
  }
  return null
}

async function download(cacheDir, log) {
  let browsers
  try {
    browsers = await import('@puppeteer/browsers')
  } catch {
    throw new Error('no browser found, and the package @puppeteer/browsers is missing to download one')
  }
  const { Browser, detectBrowserPlatform, install, resolveBuildId } = browsers
  const platform = detectBrowserPlatform()
  if (!platform) throw new Error(`no browser found, and none can be downloaded for ${process.platform} ${process.arch}`)

  // one download at a time (several verifications can start together): the others wait for it
  mkdirSync(cacheDir, { recursive: true })
  const lock = join(cacheDir, '.downloading')
  for (;;) {
    try {
      mkdirSync(lock)
      break
    } catch {
      let age = 0
      try { age = Date.now() - statSync(lock).mtimeMs } catch { continue }
      if (age > LOCK_STALE_MS) rmSync(lock, { recursive: true, force: true })
      else await sleep(1000)
    }
  }
  try {
    // downloaded by another process while this one waited
    const done = downloaded(cacheDir)
    if (done) return done
    const buildId = await resolveBuildId(Browser.CHROMEHEADLESSSHELL, platform, 'stable')
    log?.(`downloading ${SHELL} ${buildId} (${platform}) in ${cacheDir}`)
    // what an interrupted download left (install() keeps a folder that exists)
    rmSync(join(cacheDir, SHELL, `${platform}-${buildId}`), { recursive: true, force: true })
    const { executablePath } = await install({ browser: Browser.CHROMEHEADLESSSHELL, buildId, platform, cacheDir })
    writeFileSync(join(dirname(dirname(executablePath)), COMPLETE), buildId)
    return executablePath
  } finally {
    rmSync(lock, { recursive: true, force: true })
  }
}

/**
 * @returns {Promise<{ path: string, source: 'env' | 'system' | 'downloaded' }>}
 */
export async function findBrowser({ cacheDir, install = false, log = null }) {
  if (process.env.BROWSER) {
    if (!existsSync(process.env.BROWSER)) throw new Error(`BROWSER ${process.env.BROWSER} does not exist`)
    return { path: process.env.BROWSER, source: 'env' }
  }
  const system = (CANDIDATES[process.platform] || []).find((p) => existsSync(p))
  if (system) return { path: system, source: 'system' }
  const path = downloaded(cacheDir) || (install ? await download(cacheDir, log) : null)
  if (!path) throw new Error('no Chromium browser found: set BROWSER')
  return { path, source: 'downloaded' }
}

// the libraries the browser needs that the system does not have (Linux only, null when it cannot be told)
export function missingLibraries(path) {
  if (process.platform !== 'linux') return null
  const r = spawnSync('ldd', [path], { encoding: 'utf8' })
  if (r.error || r.status !== 0) return null
  return r.stdout.split('\n').filter((l) => l.includes('not found')).map((l) => l.trim().split(/\s+/)[0])
}
