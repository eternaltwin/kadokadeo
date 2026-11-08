import dayjs from 'dayjs'
import utc from 'dayjs/plugin/utc'
import { beforeEach, expect, test } from 'vitest'

import { formatDate, weekdayOf } from './dates'

dayjs.extend(utc)

// written without a zone: the same local time on every machine
const NEW_YEAR_EVE = '2026-12-31T22:05:00'

beforeEach(() => {
  delete window.Kado
})

test.each([
  ['date', '31/12/2026'],
  ['dateTime', '31/12/2026 22:05'],
  ['dateAt', '31/12/2026 à 22:05'],
  ['shortDateAt', '31/12/26 à 22:05'],
  ['dayTime', '31/12 22:05'],
  ['dayAt', '31/12 à 22:05'],
])('the %s format in French stays the one of the site', (style, expected) => {
  expect(formatDate(NEW_YEAR_EVE, style)).toBe(expected)
})

test.each([
  ['date', '12/31/2026'],
  ['dateTime', '12/31/2026 22:05'],
  ['dateAt', '12/31/2026 at 22:05'],
  ['shortDateAt', '12/31/26 at 22:05'],
  ['dayTime', '12/31 22:05'],
  ['dayAt', '12/31 at 22:05'],
])('the %s format follows English', (style, expected) => {
  window.Kado = { locale: 'en' }

  expect(formatDate(NEW_YEAR_EVE, style)).toBe(expected)
})

test('the date format is the default one', () => {
  expect(formatDate(NEW_YEAR_EVE)).toBe('31/12/2026')
})

test('a date in UTC stays in UTC near midnight', () => {
  expect(formatDate(dayjs.utc('2026-12-31T23:59:00Z'))).toBe('31/12/2026')
})

test('the day of the week follows the language', () => {
  expect(weekdayOf(NEW_YEAR_EVE)).toBe('jeudi')

  window.Kado = { locale: 'en' }

  expect(weekdayOf(NEW_YEAR_EVE)).toBe('Thursday')
})

test('a language without formats uses the French ones', () => {
  window.Kado = { locale: 'de' }

  expect(formatDate(NEW_YEAR_EVE)).toBe('31/12/2026')
})

test('a date sent to the server does not change with the language', () => {
  window.Kado = { locale: 'en' }
  formatDate(NEW_YEAR_EVE)

  expect(dayjs(NEW_YEAR_EVE).format('YYYY-MM-DD HH:mm:ss')).toBe('2026-12-31 22:05:00')
})
