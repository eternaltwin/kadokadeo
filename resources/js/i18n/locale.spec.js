import { beforeEach, expect, test, vi } from 'vitest'

import { chooseLocale, intlLocale, pageLocale, savedChoice } from './locale'

const COOKIE = 'kado_locale'

function clearCookie() {
  document.cookie = `${COOKIE}=; path=/; max-age=0`
}

beforeEach(() => {
  clearCookie()
  delete window.Kado
})

function aChoice(locale, { isLoggedIn = true, save = vi.fn().mockResolvedValue() } = {}) {
  const reload = vi.fn()
  return { save, reload, choose: () => chooseLocale(locale, { isLoggedIn, save, reload }) }
}

test('a page without a language is French', () => {
  expect(pageLocale()).toBe('fr')
  expect(intlLocale()).toBe('fr-FR')
})

test('the page gives its language', () => {
  window.Kado = { locale: 'en' }

  expect(pageLocale()).toBe('en')
  expect(intlLocale()).toBe('en')
})

test('a logged in player saves the language on the account and in the cookie, then the page reloads', async() => {
  const { save, reload, choose } = aChoice('en')

  await choose()

  expect(save).toHaveBeenCalledWith('en')
  expect(document.cookie).toContain(`${COOKIE}=en`)
  expect(reload).toHaveBeenCalledOnce()
})

test('a visitor only has the cookie', async() => {
  const { save, reload, choose } = aChoice('en', { isLoggedIn: false })

  await choose()

  expect(save).not.toHaveBeenCalled()
  expect(document.cookie).toContain(`${COOKIE}=en`)
  expect(reload).toHaveBeenCalledOnce()
})

test('the automatic choice removes the cookie, so that the browser really decides', async() => {
  document.cookie = `${COOKIE}=en; path=/`
  const { save, reload, choose } = aChoice('auto')

  await choose()

  expect(save).toHaveBeenCalledWith('auto')
  expect(document.cookie).not.toContain(COOKIE)
  expect(reload).toHaveBeenCalledOnce()
})

test('a choice the server refused changes nothing', async() => {
  const { reload, choose } = aChoice('en', { save: vi.fn().mockRejectedValue(new Error('down')) })

  await expect(choose()).rejects.toThrow('down')

  expect(document.cookie).not.toContain(COOKIE)
  expect(reload).not.toHaveBeenCalled()
})

test('the choice shown is the one of the account, then the cookie', () => {
  document.cookie = `${COOKIE}=en; path=/`

  expect(savedChoice({ locale: 'fr' })).toBe('fr')
  expect(savedChoice({ locale: 'auto' })).toBe('en')
  expect(savedChoice(null)).toBe('en')
})

test('without a valid cookie the choice shown is automatic', () => {
  expect(savedChoice(null)).toBe('auto')

  document.cookie = `${COOKIE}=klingon; path=/`

  expect(savedChoice(null)).toBe('auto')
})
