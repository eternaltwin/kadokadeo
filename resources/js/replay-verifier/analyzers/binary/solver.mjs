// The rules of Binary (resources/hx/games/binary) to value the moves of a player: a 5 x 5 grid of colors, index
// x * 5 + y (y = 0 at the bottom). A move turns a 2 x 2 block clockwise; groups of 4+ balls of a color explode
// (SCORE_BALL points each), the balls above fall, again until no group is left. The new balls get their colors at the
// end (random): the points of a move are known from the board.
export const SIZE = 5
export const EMPTY = -1
// color of the balls exploded, before they get a new color (Ball.top)
const EXPLODED = 10
const COMBO_LIMIT = 4
export const SCORE_BALL = [100, 100, 100, 100, 150, 200, 300, 400, 500, 600, 800, 1000]

const NEIGHBOURS = []
for (let i = 0; i < SIZE * SIZE; i++) {
  const x = Math.floor(i / SIZE)
  const y = i % SIZE
  const list = []
  if (x > 0) list.push(i - SIZE)
  if (x < SIZE - 1) list.push(i + SIZE)
  if (y > 0) list.push(i - 1)
  if (y < SIZE - 1) list.push(i + 1)
  NEIGHBOURS.push(list)
}

// the anchors of the moves (bottom left ball of the block): 0..3 x 0..3
export const ANCHORS = []
for (let x = 0; x < SIZE - 1; x++) for (let y = 0; y < SIZE - 1; y++) ANCHORS.push([x, y])

// Game.selectCell then updateMove (Cs.DIR): (x,y) -> (x,y+1) -> (x+1,y+1) -> (x+1,y) -> (x,y)
export function rotate(grid, x, y) {
  const g = grid.slice()
  const a = x * SIZE + y
  g[a + 1] = grid[a]
  g[a + SIZE + 1] = grid[a + 1]
  g[a + SIZE] = grid[a + SIZE + 1]
  g[a] = grid[a + SIZE]
  return g
}

// the groups of COMBO_LIMIT balls or more (Game.getGroups / checkCombo)
export function groups(grid) {
  const seen = new Uint8Array(SIZE * SIZE)
  const out = []
  for (let i = 0; i < grid.length; i++) {
    const color = grid[i]
    if (seen[i] || color === EMPTY || color === EXPLODED) continue
    const group = []
    const stack = [i]
    seen[i] = 1
    while (stack.length) {
      const j = stack.pop()
      group.push(j)
      for (const k of NEIGHBOURS[j]) {
        if (!seen[k] && grid[k] === color) {
          seen[k] = 1
          stack.push(k)
        }
      }
    }
    if (group.length >= COMBO_LIMIT) out.push(group)
  }
  return out
}

export const hasGroup = (grid) => groups(grid).length > 0

// the points of the explosions of a grid and of the falls after them (the empty cells at the top are not filled)
export function resolve(grid) {
  let g = grid.slice()
  let points = 0
  for (;;) {
    const list = groups(g)
    if (!list.length) return points
    for (const group of list) {
      for (const i of group) {
        points += SCORE_BALL[g[i]] ?? 0
        g[i] = EMPTY
      }
    }
    const next = new Array(SIZE * SIZE).fill(EMPTY)
    for (let x = 0; x < SIZE; x++) {
      let y2 = 0
      for (let y = 0; y < SIZE; y++) {
        const color = g[x * SIZE + y]
        if (color !== EMPTY) next[x * SIZE + y2++] = color
      }
    }
    g = next
  }
}

const key = (x, y) => x * SIZE + y

// the moves of a decision: the sequences of 1..maxMoves turns (the turns before the last make no group: they cost a
// "miss", the last makes one) and their points. best: the most points; firstValues: by first anchor (key), the most
// points of the sequences that begin with it; immediate: an anchor makes a group at once
export function analyzeDecision(grid, maxMoves) {
  const firstValues = new Map()
  let best = 0
  let immediate = false
  const visited = new Set()
  const explore = (g, depth, first) => {
    for (const [x, y] of ANCHORS) {
      const r = rotate(g, x, y)
      const f = first ?? key(x, y)
      if (hasGroup(r)) {
        const points = resolve(r)
        if (depth === 1) immediate = true
        if (points > (firstValues.get(f) ?? 0)) firstValues.set(f, points)
        if (points > best) best = points
      } else if (depth < maxMoves) {
        const id = f + ':' + r.join(',')
        if (visited.has(id)) continue
        visited.add(id)
        explore(r, depth + 1, f)
      }
    }
  }
  if (maxMoves > 0) explore(grid, 1, null)
  return { best, firstValues, immediate }
}

// a move of the player against the best ones: optimal (one of the first moves of the best sequences), its value (the
// most points of the sequences beginning with it), immediate (it makes a group at once)
export function rateMove(grid, maxMoves, x, y) {
  const decision = analyzeDecision(grid, maxMoves)
  const value = decision.firstValues.get(key(x, y)) ?? 0
  return {
    best: decision.best,
    value,
    optimal: decision.best > 0 && value === decision.best,
    comboAvailable: decision.immediate,
    comboTaken: hasGroup(rotate(grid, x, y)),
  }
}
