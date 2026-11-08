import { existsSync } from 'node:fs'
import { join } from 'node:path'

import { render } from '@testing-library/vue'
import { beforeEach, expect, test } from 'vitest'

import Number from './Number.vue'

const PUBLIC = join(import.meta.dirname, '../../../public')

const imagesOf = (value, props = {}) => {
  const { container } = render(Number, { props: { value, ...props } })
  return [...container.querySelectorAll('img')].map((image) => image.getAttribute('src'))
}

const hasNoMissingImage = (images) => images.forEach((image) => {
  expect(existsSync(join(PUBLIC, image)), `${image} should exist`).toBe(true)
})

beforeEach(() => {
  delete window.Kado
})

test('in French, a big number only uses images that exist', () => {
  hasNoMissingImage(imagesOf(1234567))
})

test('in English, a big number only uses images that exist', () => {
  window.Kado = { locale: 'en' }

  const images = imagesOf(1234567)

  hasNoMissingImage(images)
  expect(images).toHaveLength(9)
})

test('a signed number only uses images that exist', () => {
  window.Kado = { locale: 'en' }

  hasNoMissingImage(imagesOf(1500, { signed: true }))
})
