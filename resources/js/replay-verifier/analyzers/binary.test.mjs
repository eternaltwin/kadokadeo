// node --test resources/js/replay-verifier/analyzers/binary.test.mjs
import assert from 'node:assert/strict'
import { test } from 'node:test'

import { analyzeDecision, hasGroup, rateMove, resolve, rotate } from './binary/solver.mjs'

// a grid from rows written top (y = 4) to bottom (y = 0), one digit (color) by column x
function grid(...rows) {
  const g = new Array(25)
  rows.forEach((row, i) => [...row].forEach((c, x) => { g[x * 5 + (4 - i)] = +c }))
  return g
}

// no group at once; turning the block at 0, 0 makes a line of four 9s at y = 1 (4 x 600)
const ONE_TURN = grid(
  '38471',
  '27360',
  '16258',
  '95993',
  '94012',
)

test('a turn moves the 4 balls of the block clockwise (Cs.DIR)', () => {
  const g = grid('00000', '00000', '00000', '34000', '12000')
  // (0,0)=1 (1,0)=2 (0,1)=3 (1,1)=4 -> (0,1)=1 (1,1)=3 (1,0)=4 (0,0)=2
  assert.deepEqual(rotate(g, 0, 0), grid('00000', '00000', '00000', '13000', '24000'))
  assert.deepEqual(rotate(rotate(rotate(rotate(g, 1, 2), 1, 2), 1, 2), 1, 2), g)
})

test('the groups of 4 explode, the balls above fall and explode again', () => {
  // the four 1s explode (400), the 2s fall into a group of four 2s (400)
  const g = grid(
    '38074',
    '27963',
    '22650',
    '11549',
    '11238',
  )
  assert.equal(hasGroup(g), true)
  assert.equal(resolve(g), 800)
})

test('the best move of a board', () => {
  assert.equal(hasGroup(ONE_TURN), false)
  const best = rateMove(ONE_TURN, 1, 0, 0)
  assert.deepEqual(best, { best: 2400, value: 2400, optimal: true, comboAvailable: true, comboTaken: true })
  const other = rateMove(ONE_TURN, 1, 3, 3)
  assert.equal(other.optimal, false)
  assert.equal(other.value, 0)
  assert.equal(other.comboTaken, false)
})

test('a sequence of 2 turns counts when it gives more', () => {
  // three turns back: the block at 0, 0 must be turned twice to make the line of 9s
  const twoTurns = rotate(rotate(rotate(ONE_TURN, 0, 0), 0, 0), 0, 0)
  assert.equal(hasGroup(twoTurns), false)
  assert.equal(hasGroup(rotate(twoTurns, 0, 0)), false)
  assert.equal(analyzeDecision(twoTurns, 2).firstValues.get(0), 2400)
  assert.equal(rateMove(twoTurns, 2, 0, 0).optimal, true)
  // with one turn left, the turn at 0, 0 gives nothing
  assert.equal(rateMove(twoTurns, 1, 0, 0).value, 0)
})
