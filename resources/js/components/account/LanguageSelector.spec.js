import { fireEvent, render, screen } from '@testing-library/vue'
import { createPinia, setActivePinia } from 'pinia'
import { beforeEach, expect, test, vi } from 'vitest'

import { createAppI18n } from '@/i18n'

import LanguageSelector from './LanguageSelector.vue'

const save = vi.fn()
const reload = vi.fn()

vi.mock('@/composables/useAccount', () => ({
  useAccount: () => ({ error: { value: null }, saveLocale: save }),
}))
vi.mock('@/i18n/reload', () => ({ reloadPage: () => reload() }))

const TEXTS = { language: { title: 'Langue', auto: 'Automatique', fr: 'Français', en: 'English (beta)' } }

function renderSelector({ enabled = true } = {}) {
  window.evts = new EventTarget()
  window.Kado = { i18n_enabled: enabled, locale: 'fr' }
  const pinia = createPinia()
  setActivePinia(pinia)
  return render(LanguageSelector, { global: { plugins: [pinia, createAppI18n('fr', { fr: TEXTS })] } })
}

beforeEach(() => {
  save.mockReset().mockResolvedValue()
  reload.mockReset()
  document.cookie = 'kado_locale=; path=/; max-age=0'
})

test('with the languages off, there is no choice', () => {
  renderSelector({ enabled: false })

  expect(screen.queryByRole('combobox')).toBeNull()
})

test('with the languages on, the player reads the three choices', () => {
  renderSelector()

  expect(screen.getAllByRole('option').map((option) => option.textContent)).toEqual([
    'Automatique',
    'Français',
    'English (beta)',
  ])
})

test('a visitor who chooses a language reloads the page in it', async() => {
  renderSelector()

  await fireEvent.update(screen.getByRole('combobox'), 'en')
  await vi.waitFor(() => expect(reload).toHaveBeenCalledOnce())

  expect(document.cookie).toContain('kado_locale=en')
})
