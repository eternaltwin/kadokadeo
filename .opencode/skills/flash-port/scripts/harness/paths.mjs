// Shared locations for the test scripts: the harness server and the work folder of the ports.
//   env HPORT: port of server.py (default 8765), KKP_WORK: work folder (default ~/kadokadeo-port)
import { homedir } from 'node:os'
import { join } from 'node:path'
import { mkdirSync } from 'node:fs'

export const HOST = 'http://127.0.0.1:' + (process.env.HPORT || 8765)
export const WORK = process.env.KKP_WORK || join(homedir(), 'kadokadeo-port')
// work folder of one game (SWF, FFDec exports, out/, check/...), created if needed
export const gameDir = (pkg, ...sub) => { const d = join(WORK, pkg, ...sub); mkdirSync(d, { recursive: true }); return d }
