import { render } from '@testing-library/vue'
import { expect, test } from 'vitest'
import { h } from 'vue'
import { Translation } from 'vue-i18n'

import { createAppI18n, t } from './index'

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

test('a variable shows its value, zero included', () => {
  expect(inFrench({ score: 'Score : {points}' }).t('score', { points: 0 })).toBe('Score : 0')
})

test('the name of a player stays a text in the page', () => {
  const i18n = inFrench({ hello: 'Bonjour {name}' })

  const { container } = render({ render: () => h('p', i18n.t('hello', { name: '<b>Pirate</b>' })) })

  expect(container.textContent).toBe('Bonjour <b>Pirate</b>')
  expect(container.querySelector('b')).toBeNull()
})

test('a sentence keeps its link when it is translated', () => {
  const i18n = createAppI18n('en', { fr: { rules: 'Lisez {link}' }, en: { rules: 'Read {link}' } })

  const { container } = render(
    { render: () => h(Translation, { keypath: 'rules', tag: 'p' }, { link: () => h('a', { href: '/rules' }, 'the rules') }) },
    { global: { plugins: [i18n] } },
  )

  expect(container.textContent).toBe('Read the rules')
  expect(container.querySelector('a').getAttribute('href')).toBe('/rules')
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

test('a store reads a text outside a component, in the language of the page', () => {
  createAppI18n('en', { fr: { hello: 'Bonjour {name}', bye: 'Salut' }, en: { hello: 'Hello {name}' } })

  expect(t('hello', { name: 'Mel' })).toBe('Hello Mel')
  expect(t('bye')).toBe('Salut')
})
