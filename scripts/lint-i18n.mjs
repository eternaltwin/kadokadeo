// The translation catalogs of resources/lang/ against each other and against the code, checked in the CI:
//   node scripts/lint-i18n.mjs
import { readdirSync, readFileSync } from 'node:fs'
import { join, relative } from 'node:path'
import { fileURLToPath } from 'node:url'

import { baseCompile } from '@intlify/message-compiler'

const ROOT = join(import.meta.dirname, '..')
const LANG = join(ROOT, 'resources/lang')
const JS = join(ROOT, 'resources/js')
const SOURCE_LANGUAGE = 'fr'
// generated or not part of the site: the games (Haxe), the replay verifier (Node)
const NOT_THE_SITE = [join(JS, 'games'), join(JS, 'replay-verifier')]

// { login: { title: 'x' } } -> [['login.title', 'x']]
const flatten = (messages, prefix = '') =>
  Object.entries(messages).flatMap(([key, value]) => {
    const path = prefix ? `${prefix}.${key}` : key
    return value !== null && typeof value === 'object' ? flatten(value, path) : [[path, value]]
  })

// {name} is a variable, {'@'} an escaped character
const variablesOf = (message) =>
  [...new Set([...message.matchAll(/\{\s*([A-Za-z_]\w*)\s*\}/g)].map((match) => match[1]))].sort().join(', ')

function syntaxErrorsOf(message) {
  const errors = []
  baseCompile(message, { onError: (error) => errors.push(error.message) })
  return errors
}

function messageProblems(language, key, message) {
  if (typeof message !== 'string') {
    return [`${language}: ${key} is not a text`]
  }
  return [
    ...(message.includes('<') ? [`${language}: ${key} holds "<": a tag stays in the component (<i18n-t>)`] : []),
    ...syntaxErrorsOf(message).map((error) => `${language}: ${key}: ${error}`),
  ]
}

export function findCatalogProblems(french, translations) {
  const frenchEntries = flatten(french)
  const frenchMessages = new Map(frenchEntries)
  const problems = frenchEntries.flatMap(([key, message]) => messageProblems(SOURCE_LANGUAGE, key, message))

  for (const [language, messages] of Object.entries(translations)) {
    for (const [key, message] of flatten(messages)) {
      problems.push(...messageProblems(language, key, message))
      const source = frenchMessages.get(key)
      const isComparable = typeof source === 'string' && typeof message === 'string' && message !== ''
      if (isComparable && variablesOf(source) !== variablesOf(message)) {
        problems.push(`${language}: ${key} has the variables [${variablesOf(message)}], the French text [${variablesOf(source)}]`)
      }
    }
  }
  return problems
}

export function findMissingTranslations(french, translations) {
  const frenchKeys = flatten(french).map(([key]) => key)
  return Object.entries(translations).flatMap(([language, messages]) => {
    const translatedKeys = new Set(flatten(messages).filter(([, message]) => message !== '').map(([key]) => key))
    return frenchKeys.filter((key) => !translatedKeys.has(key)).map((key) => `${language}: ${key} has no translation`)
  })
}

const withoutComments = (code) =>
  code
    .replaceAll(/<!--[\s\S]*?-->/g, '')
    .replaceAll(/\/\*[\s\S]*?\*\//g, '')
    .replaceAll(/(^|\s)\/\/.*$/gm, '')

export function findUsageProblems(code, frenchKeys, file) {
  const readable = withoutComments(code)
  const quotedArguments = [
    ...[...readable.matchAll(/\bt\(\s*([^\s,)]*)/g)].map((match) => match[1]),
    ...[...readable.matchAll(/(?<![:\w-])keypath="([^"]*)"/g)].map((match) => `'${match[1]}'`),
    ...[...readable.matchAll(/:keypath="([^"]*)"/g)].map((match) => match[1]),
  ]
  return quotedArguments.flatMap((argument) => {
    const key = argument.match(/^(['"])([^'"]+)\1$/)?.[2]
    if (key === undefined) {
      return [`${file}: the key ${argument || '(none)'} is not a literal: use a table of literal keys`]
    }
    return frenchKeys.has(key) ? [] : [`${file}: the key ${key} is not in resources/lang/${SOURCE_LANGUAGE}/site.json`]
  })
}

export function parseCatalog(text, file) {
  try {
    return { messages: JSON.parse(text), problems: [] }
  } catch (error) {
    return { messages: {}, problems: [`${file}: ${error.message}`] }
  }
}

export function siteCatalogOf(language) {
  const path = join(LANG, language, 'site.json')
  return parseCatalog(readFileSync(path, 'utf8'), relative(ROOT, path))
}

function siteFiles(directory) {
  return readdirSync(directory, { withFileTypes: true }).flatMap((entry) => {
    const path = join(directory, entry.name)
    if (NOT_THE_SITE.includes(path)) return []
    if (entry.isDirectory()) return siteFiles(path)
    const isTest = /\.(spec|test)\.m?js$/.test(entry.name)
    return !isTest && /\.(vue|js)$/.test(entry.name) ? [path] : []
  })
}

function findAllProblems() {
  const french = siteCatalogOf(SOURCE_LANGUAGE)
  const languages = readdirSync(LANG).filter((language) => language !== SOURCE_LANGUAGE)
  const translations = languages.map((language) => [language, siteCatalogOf(language)])
  const frenchKeys = new Set(flatten(french.messages).map(([key]) => key))

  return [
    ...french.problems,
    ...translations.flatMap(([, catalog]) => catalog.problems),
    ...findCatalogProblems(
      french.messages,
      Object.fromEntries(translations.map(([language, catalog]) => [language, catalog.messages])),
    ),
    ...siteFiles(JS).flatMap((file) => findUsageProblems(readFileSync(file, 'utf8'), frenchKeys, relative(ROOT, file))),
  ]
}

if (process.argv[1] === fileURLToPath(import.meta.url)) {
  const problems = findAllProblems()
  if (problems.length) {
    console.error(problems.join('\n'))
    console.error(`\n${problems.length} problem(s) in the translations`)
    process.exit(1)
  }
  console.log('Translation catalogs: OK')
}
