// node --test scripts/eslint-i18n.test.mjs
// The rule against the texts written in the code, on the migrated files of eslint.config.js
import assert from 'node:assert/strict'
import { test } from 'node:test'

import { ESLint } from 'eslint'

const MIGRATED_FILE = 'resources/js/pages/login.vue'
const OTHER_FILE = 'resources/js/pages/clans/debug.vue'

const eslint = new ESLint()

async function textRuleFindings(code, filePath = MIGRATED_FILE) {
  const [result] = await eslint.lintText(code, { filePath })
  return result.messages.filter((message) => message.fatal || message.message.includes('t()') || message.ruleId === 'vue/no-bare-strings-in-template')
}

const page = ({ template = '<p />', script = '' }) => `<script setup>\n${script}\n</script>\n\n<template>\n  ${template}\n</template>\n`

const isRefused = async(code) => assert.notDeepEqual(await textRuleFindings(code), [], `should be refused: ${code}`)
const isAccepted = async(code, filePath) => assert.deepEqual(await textRuleFindings(code, filePath), [])

test('a text written in a template is refused', () => isRefused(page({ template: '<p>Bonjour</p>' })))

test('a displayed attribute is refused', async() => {
  await isRefused(page({ template: '<input placeholder="Votre nom">' }))
  await isRefused(page({ template: '<a title="Jouer" />' }))
})

test('the label of a component is refused', () => isRefused(page({ template: '<NavTab label="Compte" />' })))

test('an accented text in a script is refused', () => isRefused(page({ script: "toast('Déjà pris')" })))

test('an accented template literal is refused', () => isRefused(page({ script: 'const message = `Déjà ${name}`' })))

test('an accented text in an expression of a template is refused', () => isRefused(page({ template: "<p>{{ 'Déjà' }}</p>" })))

test('a text through t() is accepted', () => isAccepted(page({ template: "<p>{{ $t('a.b') }}</p>" })))

test('numbers and punctuation are accepted', async() => {
  await isAccepted(page({ template: '<p>123</p>' }))
  await isAccepted(page({ template: '<p>·</p>' }))
})

test('an accented comment is accepted', () => isAccepted(page({ script: '// Déjà pris' })))

test('a text outside the migrated files is accepted', () => isAccepted(page({ template: '<p>Bonjour</p>' }), OTHER_FILE))

test('a migrated store is refused an accented text, but can call useApi', async() => {
  const filePath = 'resources/js/stores/messages.js'

  assert.notDeepEqual(await textRuleFindings("toast('Déjà pris')", filePath), [])
  const [result] = await eslint.lintText('useApi()', { filePath })
  assert.ok(!result.messages.some((message) => message.message.includes('composable')), 'a store can call useApi')
})

test('useApi stays refused in a migrated file', async() => {
  const [result] = await eslint.lintText(page({ script: 'useApi()' }), { filePath: MIGRATED_FILE })

  assert.ok(result.messages.some((message) => message.message.includes('composable')), 'the rule of useApi should stay')
})
