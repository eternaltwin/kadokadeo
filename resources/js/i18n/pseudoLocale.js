// A language for the checks only, from the French catalogs: every text gets longer and can be recognized.
// A replay that changes with it reads a text in its logic; a text that stays normal on the screen cannot be translated.
const MARK = 'XX'
// what the code of a game reads in a text: its variables, and the separators of its lists
const KEPT_AS_THEY_ARE = /(\{[A-Za-z_]\w*\}|\$[np]|[|,\r\n\t]+)/

const isKept = (part) => part.trim() === '' || KEPT_AS_THEY_ARE.test(part)

export const pseudoText = (text) =>
  text
    .split(KEPT_AS_THEY_ARE)
    .map((part) => (isKept(part) ? part : `${MARK}${part}${MARK}`))
    .join('')

export const pseudoCatalog = (catalog) =>
  Object.fromEntries(
    Object.entries(catalog).map(([key, value]) => [key, typeof value === 'string' ? pseudoText(value) : pseudoCatalog(value)]),
  )
