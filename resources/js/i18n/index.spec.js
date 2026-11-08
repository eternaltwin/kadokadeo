import { expect, test } from 'vitest'

import { createAppI18n } from './index'

const PLAYERS = { players: 'Un joueur | {n} joueurs' }
const ENGLISH_PLAYERS = { players: 'One player | {n} players' }

const inEnglish = (french, english) => createAppI18n('en', { fr: french, en: english }).global
const inFrench = (french) => createAppI18n('fr', { fr: french }).global

test('a key without a translation shows the French text', () => {
  expect(inEnglish({ hello: 'Bonjour' }, {}).t('hello')).toBe('Bonjour')
})

test('an empty translation shows the French text', () => {
  expect(inEnglish({ hello: 'Bonjour' }, { hello: '' }).t('hello')).toBe('Bonjour')
  expect(inEnglish({ login: { hello: 'Bonjour' } }, { login: { hello: '' } }).t('login.hello')).toBe('Bonjour')
})

test('a translated key shows its translation', () => {
  expect(inEnglish({ hello: 'Bonjour' }, { hello: 'Hello' }).t('hello')).toBe('Hello')
})

test.each([
  [0, 'Un joueur'],
  [1, 'Un joueur'],
  [2, '2 joueurs'],
])('in French, %i gives "%s"', (count, expected) => {
  expect(inFrench(PLAYERS).t('players', { n: count }, count)).toBe(expected)
})

test.each([
  [0, '0 players'],
  [1, 'One player'],
  [2, '2 players'],
])('in English, %i gives "%s"', (count, expected) => {
  expect(inEnglish(PLAYERS, ENGLISH_PLAYERS).t('players', { n: count }, count)).toBe(expected)
})
