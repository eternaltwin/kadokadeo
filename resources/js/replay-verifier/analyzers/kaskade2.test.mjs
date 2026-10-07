// node --test resources/js/replay-verifier/analyzers/kaskade2.test.mjs
import assert from 'node:assert/strict'
import { test } from 'node:test'

import { afterMove, groupAt, groups, points, rateMove, UNKNOWN } from './kaskade2/solver.mjs'

// a grid from rows y = 0..7, one digit (color) by column x; 5: a ball that makes no group (Const.MAXCOLORS - 1)
function grid(...rows) {
  const g = new Array(64)
  rows.forEach((row, y) => [...row].forEach((c, x) => { g[x * 8 + y] = c === '.' ? UNKNOWN : +c }))
  return g
}

const FILLER = '55555555'

test('the points grow with the square of the group', () => {
  assert.deepEqual([2, 3, 6, 10].map(points), [100, 300, 1500, 4500])
})

test('the groups: 2 balls or more of a color, never the color 5', () => {
  const g = grid('00011000', '55555555', '55555555', '55555555', '55555555', '55555555', '55555555', '55555555')
  assert.deepEqual(groups(g).map((x) => x.cells.length).sort(), [2, 3, 3])
  assert.equal(groupAt(g, 3, 1), null)
})

test('the balls slide to the right, then down; the holes are unknown', () => {
  // the ball at 7, 0 destroyed: the row slides one cell to the right
  const g = grid('01201201', FILLER, FILLER, FILLER, FILLER, FILLER, FILLER, FILLER)
  const after = afterMove(g, [7 * 8 + 0])
  assert.deepEqual(after, grid('.0120120', FILLER, FILLER, FILLER, FILLER, FILLER, FILLER, FILLER))
  // the ball at 0, 7 destroyed (nothing on its left): the column falls one cell (y + 1)
  const column = grid('01201201', '12012012', FILLER, FILLER, FILLER, FILLER, FILLER, '20120120')
  assert.deepEqual(afterMove(column, [0 * 8 + 7]), grid('.1201201', '02012012', '15555555', FILLER, FILLER, FILLER, FILLER, '50120120'))
})

test('the best move grows a group for later, not always the biggest group', () => {
  // 0 0 0 1 1 0 0 0: the 1s destroyed (100) join the two groups of 0s (6 balls: 1500)
  const g = grid('00011000', FILLER, FILLER, FILLER, FILLER, FILLER, FILLER, FILLER)
  const setUp = rateMove(g, 2, 3, 0)
  assert.equal(setUp.value, 100 + 1500)
  assert.equal(setUp.optimal, true)
  assert.equal(setUp.greedy, false)
  const greedy = rateMove(g, 2, 0, 0)
  assert.equal(greedy.value, 300 + 300)
  assert.equal(greedy.optimal, false)
  assert.equal(greedy.greedy, true)
  // one move left: the biggest group is the best
  assert.equal(rateMove(g, 1, 0, 0).optimal, true)
})
