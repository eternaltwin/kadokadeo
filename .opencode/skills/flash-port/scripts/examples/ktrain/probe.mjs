// Opens a harness page, waits, prints the console and a few values (debug of the port).
// usage: node probe.mjs <url> [ms] [js expr]   env: PORT
import { launch } from '../../harness/cdp.mjs'
const b = await launch(+(process.env.PORT || 9882))
try {
  await b.goto(process.argv[2])
  await b.sleep(+(process.argv[3] || 5000))
  console.log(b.consoleLines.slice(-40).join('\n'))
  if (process.argv[4]) console.log('EVAL', await b.eval(process.argv[4]))
} finally { await b.close() }
