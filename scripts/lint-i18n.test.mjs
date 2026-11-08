// node --test scripts/lint-i18n.test.mjs
import assert from 'node:assert/strict'
import { test } from 'node:test'

import { findCatalogProblems, findMissingTranslations, findUsageProblems, parseCatalog } from './lint-i18n.mjs'

const catalogsAreRejected = (french, english) =>
  assert.notDeepEqual(findCatalogProblems(french, { en: english }), [], 'these catalogs should be rejected')
const catalogsAreAccepted = (french, english) =>
  assert.deepEqual(findCatalogProblems(french, { en: english }), [])

const codeIsRejected = (code, frenchKeys = []) =>
  assert.notDeepEqual(findUsageProblems(code, new Set(frenchKeys), 'page.vue'), [], `this code should be rejected: ${code}`)
const codeIsAccepted = (code, frenchKeys = []) =>
  assert.deepEqual(findUsageProblems(code, new Set(frenchKeys), 'page.vue'), [])

test('a supported language must translate every key', () => {
  assert.deepEqual(findMissingTranslations({ hello: 'Bonjour', bye: 'Salut' }, { en: { hello: 'Hello' } }), [
    'en: bye has no translation',
  ])
})

test('an empty text is not a translation', () => {
  assert.deepEqual(findMissingTranslations({ hello: 'Bonjour' }, { en: { hello: '' } }), [
    'en: hello has no translation',
  ])
})

test('nested keys must be translated too', () => {
  assert.deepEqual(findMissingTranslations({ login: { hello: 'Bonjour' } }, { en: { login: {} } }), [
    'en: login.hello has no translation',
  ])
})

test('every supported language is checked', () => {
  assert.deepEqual(findMissingTranslations({ hello: 'Bonjour' }, { en: {}, es: {} }), [
    'en: hello has no translation',
    'es: hello has no translation',
  ])
})

test('a complete language is accepted', () => {
  assert.deepEqual(findMissingTranslations({ login: { hello: 'Bonjour' } }, { en: { login: { hello: 'Hello' } } }), [])
})

test('a translation that drops a variable is rejected', () => {
  catalogsAreRejected({ hello: 'Bonjour {name}' }, { hello: 'Hello' })
})

test('a translation that invents a variable is rejected', () => {
  catalogsAreRejected({ hello: 'Bonjour' }, { hello: 'Hello {name}' })
})

test('the same variables in another order are accepted', () => {
  catalogsAreAccepted({ duel: '{winner} bat {loser}' }, { duel: '{loser} lost to {winner}' })
})

test('a variable in one branch of a plural is accepted', () => {
  catalogsAreAccepted({ players: 'Un joueur | {n} joueurs' }, { players: 'One player | {n} players' })
})

test('a variable that only the French plural uses is rejected', () => {
  catalogsAreRejected({ players: 'Un joueur | {n} joueurs' }, { players: 'One player | Many players' })
})

test('an escaped brace is not a variable', () => {
  catalogsAreAccepted({ mail: "kado{'@'}site.fr" }, { mail: "kado{'@'}site.com" })
})

test('a missing or empty translation is accepted', () => {
  catalogsAreAccepted({ hello: 'Bonjour {name}', bye: 'Salut {name}' }, { bye: '' })
})

test('nested keys are compared', () => {
  catalogsAreRejected({ login: { hello: 'Bonjour {name}' } }, { login: { hello: 'Hello' } })
})

test('markup in a catalog is rejected, in French as in a translation', () => {
  catalogsAreRejected({ hello: '<b>Bonjour</b>' }, {})
  catalogsAreRejected({ hello: 'Bonjour' }, { hello: '<b>Hello</b>' })
})

test('a message with a broken syntax is rejected', () => {
  catalogsAreRejected({ mail: 'kado@site.fr' }, {})
  catalogsAreRejected({ hello: 'Bonjour {name' }, {})
})

test('a value that is not a text is rejected', () => {
  catalogsAreRejected({ count: 3 }, {})
  catalogsAreRejected({ hello: 'Bonjour' }, { hello: 3 })
  catalogsAreRejected({ hello: null }, {})
})

test('a key used by the code and missing in French is rejected', () => {
  codeIsRejected("t('login.title')")
  codeIsRejected("$t('login.title')")
  codeIsRejected('<i18n-t keypath="login.title" />')
})

test('a key known in French is accepted', () => {
  codeIsAccepted("t('login.title')", ['login.title'])
  codeIsAccepted('t("login.title", { name })', ['login.title'])
  codeIsAccepted('<i18n-t keypath="login.title" />', ['login.title'])
  codeIsAccepted(`<i18n-t :keypath="'login.title'" />`, ['login.title'])
})

test('a key that is not a literal is rejected', () => {
  codeIsRejected('t(key)')
  codeIsRejected('t(`login.${name}`)')
  codeIsRejected('<i18n-t :keypath="key" />')
})

test('the words that only end with a t are not translations', () => {
  codeIsAccepted('list.at(0); wait(delay); format(value)')
})

test('a key in a comment is ignored', () => {
  codeIsAccepted("// t('login.title')")
  codeIsAccepted("/* t('login.title') */")
  codeIsAccepted("<!-- t('login.title') -->")
})

test('a link is not taken for a comment', () => {
  codeIsRejected("const url = 'https://kado.fr'; t('login.title')")
})

test('an unreadable catalog names its file', () => {
  const { problems } = parseCatalog('{ not json', 'resources/lang/en/site.json')

  assert.equal(problems.length, 1)
  assert.match(problems[0], /lang\/en\/site\.json/)
})

test('a readable catalog gives its messages', () => {
  assert.deepEqual(parseCatalog('{"hello":"Bonjour"}', 'resources/lang/fr/site.json'), {
    messages: { hello: 'Bonjour' },
    problems: [],
  })
})
