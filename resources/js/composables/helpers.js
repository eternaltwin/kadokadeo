export function formatScore(score) {
  return Number(score).toLocaleString('fr-FR').replace(/\u202f/g, ' ')
}

export function formatTime(seconds) {
  if (isNaN(seconds) || seconds < 0) {
    return '??:??'
  }

  const h = Math.floor(seconds / 3600)
  const m = Math.floor((seconds % 3600) / 60)
  const s = seconds % 60

  if (h > 0) {
    return `${String(h).padStart(2, '0')}:${String(m).padStart(2, '0')}:${String(s).padStart(2, '0')}`
  }

  return `${String(m).padStart(2, '0')}:${String(s).padStart(2, '0')}`
}

export function updateAtMidnight() {
  return new Promise((resolve) => {
    const now = dayjs().utc()
    const tomorrow = now.add(1, 'day').startOf('day')
    const msUntilMidnight = tomorrow.diff(now, 'millisecond') + 1000 // add 1 second to be sure we are past midnight

    setTimeout(resolve, msUntilMidnight)
  })
}
