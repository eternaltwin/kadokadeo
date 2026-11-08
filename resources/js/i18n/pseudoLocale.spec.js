import { expect, test } from 'vitest'

import { pseudoCatalog, pseudoText } from './pseudoLocale'

test('a text gets longer and can be recognized', () => {
  expect(pseudoText('SAUTE !')).toBe('XXSAUTE !XX')
})

test('a variable stays usable', () => {
  expect(pseudoText('UniCombo +{_c}')).toBe('XXUniCombo +XX{_c}')
  expect(pseudoText('{winner} bat {loser}')).toBe('{winner}XX bat XX{loser}')
})

test('the lists keep their length', () => {
  const text = 'Nouvelle Chine,Russinia|Franicie'

  expect(pseudoText(text)).toBe('XXNouvelle ChineXX,XXRussiniaXX|XXFranicieXX')
  expect(pseudoText(text).split(/[,|]/)).toHaveLength(3)
})

test('the marks of Mel stay', () => {
  expect(pseudoText('flash : $n vous ment.\r\n\t')).toBe('XXflash : XX$nXX vous ment.XX\r\n\t')
  expect(pseudoText('la $p')).toBe('XXla XX$p')
})

test('an empty text stays empty', () => {
  expect(pseudoText('')).toBe('')
})

test('spaces alone stay as they are', () => {
  expect(pseudoText('  ')).toBe('  ')
})

test('only ASCII is added: some fonts of the games have few characters', () => {
  expect(pseudoText('été')).toBe('XXétéXX')
})

test('a catalog keeps its keys, nested or not', () => {
  expect(pseudoCatalog({ 'lvl_1&dbl': 'Saut', 'players.one': 'Un', login: { hello: 'Salut' } })).toEqual({
    'lvl_1&dbl': 'XXSautXX',
    'players.one': 'XXUnXX',
    login: { hello: 'XXSalutXX' },
  })
})
