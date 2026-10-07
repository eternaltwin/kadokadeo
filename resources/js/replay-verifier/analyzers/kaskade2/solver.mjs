// The rules of Kaskade 2 (resources/hx/games/kaskade2) to value the moves of a player: an 8 x 8 grid of colors, index
// x * 8 + y. A move destroys a group of 2+ balls of a color (n balls: n * (n - 1) / 2 * 100 points); the balls slide
// to the right (x + 1) then down (y + 1), one cell at a time (Level.gravity), and the holes get new random balls: unknown
// here, so the value of a move counts the points certain from the board only (what a solver can show).
export const SIZE = 8
export const UNKNOWN = -1
// Const.MAXCOLORS - 1: balls that make no group
const NO_GROUP_COLOR = 5

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

export const points = (n) => (n * (n - 1)) / 2 * 100

// the groups a click destroys (Level.makeGroups): connected balls of a color, 2 or more; key: the smallest index
export function groups(grid) {
  const seen = new Uint8Array(SIZE * SIZE)
  const out = []
  for (let i = 0; i < grid.length; i++) {
    const color = grid[i]
    if (seen[i] || color === UNKNOWN || color === NO_GROUP_COLOR) continue
    const cells = []
    const stack = [i]
    seen[i] = 1
    while (stack.length) {
      const j = stack.pop()
      cells.push(j)
      for (const k of NEIGHBOURS[j]) {
        if (!seen[k] && grid[k] === color) {
          seen[k] = 1
          stack.push(k)
        }
      }
    }
    if (cells.length >= 2) out.push({ key: Math.min(...cells), cells })
  }
  return out
}

// the group of a cell (null: the cell makes no group)
export function groupAt(grid, x, y) {
  const i = x * SIZE + y
  return groups(grid).find((g) => g.cells.includes(i)) ?? null
}

const EMPTY = -2

// Level.gravity: one step to the right in every row while a ball can move, else one step down in every column; again
// until nothing moves. The holes left get new balls (unknown).
export function afterMove(grid, cells) {
  const g = grid.slice()
  for (const i of cells) g[i] = EMPTY
  const stepRight = () => {
    let moved = false
    for (let y = 0; y < SIZE; y++) {
      let space = false
      for (let x = SIZE - 1; x >= 0; x--) {
        const i = x * SIZE + y
        if (g[i] === EMPTY) space = true
        else if (space) {
          g[i + SIZE] = g[i]
          g[i] = EMPTY
          moved = true
        }
      }
    }
    return moved
  }
  const stepDown = () => {
    let moved = false
    for (let x = 0; x < SIZE; x++) {
      let space = false
      for (let y = SIZE - 1; y >= 0; y--) {
        const i = x * SIZE + y
        if (g[i] === EMPTY) space = true
        else if (space) {
          g[i + 1] = g[i]
          g[i] = EMPTY
          moved = true
        }
      }
    }
    return moved
  }
  while (stepRight() || stepDown()) {
    // until nothing moves
  }
  for (let i = 0; i < g.length; i++) if (g[i] === EMPTY) g[i] = UNKNOWN
  return g
}

// the most points certain in `depth` moves from a grid
function bestValue(grid, depth, memo) {
  if (depth <= 0) return 0
  const id = depth + ':' + grid.join(',')
  const known = memo.get(id)
  if (known !== undefined) return known
  let best = 0
  for (const group of groups(grid)) {
    const value = points(group.cells.length) + (depth > 1 ? bestValue(afterMove(grid, group.cells), depth - 1, memo) : 0)
    if (value > best) best = value
  }
  memo.set(id, best)
  return best
}

// a move of the player (the group of the cell x, y) against the best ones, looking `depth` moves ahead: optimal (one of
// the first moves of the best sequences), its value (the most points of the sequences beginning with it), greedy (the
// biggest group of the board)
export function rateMove(grid, depth, x, y) {
  const played = groupAt(grid, x, y)
  const memo = new Map()
  let best = 0
  let value = 0
  let biggest = 0
  for (const group of groups(grid)) {
    const v = points(group.cells.length) + (depth > 1 ? bestValue(afterMove(grid, group.cells), depth - 1, memo) : 0)
    if (v > best) best = v
    if (played && group.key === played.key) value = v
    if (group.cells.length > biggest) biggest = group.cells.length
  }
  return {
    best,
    value,
    optimal: played !== null && best > 0 && value === best,
    greedy: played !== null && played.cells.length === biggest,
    size: played ? played.cells.length : 0,
  }
}
