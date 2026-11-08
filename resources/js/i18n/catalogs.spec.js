import { afterEach, beforeEach, expect, test, vi } from 'vitest'

import { loadGameTexts, loadLocale } from './catalogs'
import { createAppI18n } from './index'

const SITE = '/resources/lang/en/site.json'
const KADO = '/resources/lang/en/kado.json'
const MEL = '/resources/lang/en/games/mel.json'

const neverAnswers = () => new Promise(() => {})

const anEnglishSite = () => createAppI18n('en', { fr: { hello: 'Bonjour', bye: 'Salut' } })

beforeEach(() => {
  vi.useFakeTimers()
})

afterEach(() => {
  vi.useRealTimers()
})

test('French downloads nothing on the site', async() => {
  const loader = vi.fn()
  const i18n = createAppI18n('fr', { fr: { hello: 'Bonjour' } })

  await loadLocale(i18n, 'fr', { '/resources/lang/fr/site.json': loader })

  expect(loader).not.toHaveBeenCalled()
  expect(i18n.global.t('hello')).toBe('Bonjour')
})

test('English comes with its catalog, French for the rest', async() => {
  const i18n = anEnglishSite()

  await loadLocale(i18n, 'en', { [SITE]: async() => ({ hello: 'Hello' }) })

  expect(i18n.global.t('hello')).toBe('Hello')
  expect(i18n.global.t('bye')).toBe('Salut')
})

test('an empty text of a catalog stays French', async() => {
  const i18n = anEnglishSite()

  await loadLocale(i18n, 'en', { [SITE]: async() => ({ hello: '' }) })

  expect(i18n.global.t('hello')).toBe('Bonjour')
})

test('a catalog that fails leaves the site in French', async() => {
  const i18n = anEnglishSite()

  await loadLocale(i18n, 'en', { [SITE]: async() => { throw new Error('offline') } })

  expect(i18n.global.t('hello')).toBe('Bonjour')
})

test('a language without a catalog leaves the site in French', async() => {
  const i18n = anEnglishSite()

  await loadLocale(i18n, 'en', {})

  expect(i18n.global.t('hello')).toBe('Bonjour')
})

test('the site does not wait for a catalog after 3 seconds', async() => {
  const i18n = anEnglishSite()
  const loaded = vi.fn()

  loadLocale(i18n, 'en', { [SITE]: neverAnswers }).then(loaded)
  await vi.advanceTimersByTimeAsync(2999)
  expect(loaded).not.toHaveBeenCalled()
  await vi.advanceTimersByTimeAsync(1)

  expect(loaded).toHaveBeenCalledOnce()
  expect(i18n.global.t('hello')).toBe('Bonjour')
})

test('a catalog that answers after 3 seconds is ignored', async() => {
  const i18n = anEnglishSite()
  let answer
  const late = () => new Promise((resolve) => { answer = resolve })

  const loading = loadLocale(i18n, 'en', { [SITE]: late })
  await vi.advanceTimersByTimeAsync(3000)
  await loading
  answer({ hello: 'Hello' })
  await vi.advanceTimersByTimeAsync(0)

  expect(i18n.global.t('hello')).toBe('Bonjour')
})

test('French downloads nothing for a game', async() => {
  const loader = vi.fn()

  expect(await loadGameTexts('fr', 'mel', { '/resources/lang/fr/kado.json': loader })).toEqual({})
  expect(loader).not.toHaveBeenCalled()
})

test('a game gets its catalog and the shared one, each under its name', async() => {
  const texts = await loadGameTexts('en', 'mel', {
    [KADO]: async() => ({ score: 'Shared' }),
    [MEL]: async() => ({ score: 'Of the game' }),
  })

  expect(texts).toEqual({ kado: { score: 'Shared' }, 'games/mel': { score: 'Of the game' } })
})

test('a game without a catalog still gets the shared one', async() => {
  expect(await loadGameTexts('en', 'trigo', { [KADO]: async() => ({ score: 'Shared' }) })).toEqual({
    kado: { score: 'Shared' },
  })
})

test('the catalog of another game is never read', async() => {
  const other = vi.fn()

  await loadGameTexts('en', 'mel', { '/resources/lang/en/games/trigo.json': other })

  expect(other).not.toHaveBeenCalled()
})

test('one catalog that fails does not lose the other', async() => {
  const texts = await loadGameTexts('en', 'mel', {
    [KADO]: async() => { throw new Error('offline') },
    [MEL]: async() => ({ jump: 'JUMP!' }),
  })

  expect(texts).toEqual({ 'games/mel': { jump: 'JUMP!' } })
})

test('a game starts in French when its catalogs fail', async() => {
  const fails = async() => { throw new Error('offline') }

  expect(await loadGameTexts('en', 'mel', { [KADO]: fails, [MEL]: fails })).toEqual({})
})

test('a game does not wait for a catalog after 3 seconds', async() => {
  const loaded = vi.fn()

  loadGameTexts('en', 'mel', { [KADO]: async() => ({ score: 'Shared' }), [MEL]: neverAnswers }).then(loaded)
  await vi.advanceTimersByTimeAsync(3000)

  expect(loaded).toHaveBeenCalledWith({ kado: { score: 'Shared' } })
})
