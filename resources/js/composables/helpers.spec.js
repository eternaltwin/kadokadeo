import { beforeEach, expect, test } from 'vitest'

import { formatScore } from './helpers'

beforeEach(() => {
  delete window.Kado
})

test.each([
  [0, '0'],
  [999, '999'],
  [1000, '1 000'],
  [1234567, '1 234 567'],
  ['1000', '1 000'],
  [null, '0'],
])('in French, %s is shown as "%s"', (score, expected) => {
  expect(formatScore(score).replaceAll(' ', ' ')).toBe(expected)
})

test('a score has no special space that a line can break on', () => {
  expect(formatScore(1000)).not.toContain(' ')
})

test('in English, a score uses a comma', () => {
  window.Kado = { locale: 'en' }

  expect(formatScore(1000)).toBe('1,000')
})

test('a list of scores can use it directly: its index is not a language', () => {
  expect([1000].map(formatScore)[0].replaceAll(' ', ' ')).toBe('1 000')
})
