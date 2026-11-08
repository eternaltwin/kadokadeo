import { render, screen } from '@testing-library/vue'
import { expect, test } from 'vitest'

import Notice from './Notice.vue'

test.each(['error', 'success', 'warning'])('a %s notice shows the text it is given', (variant) => {
  render(Notice, { props: { variant }, slots: { default: 'Votre partie est enregistrée' } })

  expect(screen.getByText('Votre partie est enregistrée')).toBeTruthy()
})
