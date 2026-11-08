/** @spec i18n.site::french-unchanged */
import { render, screen } from '@testing-library/vue'
import { createPinia } from 'pinia'
import { expect, test } from 'vitest'

import french from '../../lang/fr/site.json'
import { createAppI18n } from '../i18n'
import LoginPage from './login.vue'

function renderLoginPage(locale = 'fr', translations = {}) {
  // created by the layout of the site (resources/views/layouts/default.blade.php)
  window.evts = new EventTarget()
  const i18n = createAppI18n(locale, { [locale]: translations, fr: french })
  return render(LoginPage, { global: { plugins: [createPinia(), i18n] } })
}

test('a French player reads the texts of the page', () => {
  renderLoginPage()

  for (const text of [
    'Bienvenue',
    'Des jeux',
    'Plus de 70 jeux exclusifs à débloquer !',
    'Plein d\'amis',
    '... et d\'adversaires dans une communauté de joueurs pleine de bonne humeur !',
    '>> Jouer <<',
  ]) {
    expect(screen.getByText(text)).toBeTruthy()
  }
})

test('the play link stays a link to the login, with its title', () => {
  renderLoginPage()

  const link = screen.getByRole('link', { name: '>> Jouer <<' })

  expect(link.getAttribute('href')).toBe('/login')
  expect(link.getAttribute('title')).toBe('S\'identifier / s\'inscrire')
})

test('an English player gets the translated texts, and French for the others', () => {
  renderLoginPage('en', { login: { welcome: 'Welcome', play: 'Play', play_title: 'Log in / sign up' } })

  const link = screen.getByRole('link', { name: '>> Play <<' })

  expect(screen.getByText('Welcome')).toBeTruthy()
  expect(link.getAttribute('href')).toBe('/login')
  expect(link.getAttribute('title')).toBe('Log in / sign up')
  expect(screen.getByText('Des jeux')).toBeTruthy()
})
