// The catalogs of the other languages, downloaded on demand: French is in the bundles.
// A catalog that fails or does not answer never blocks the site or a game: their texts stay in French.
import { withoutEmptyTexts } from './index'
import { pseudoCatalog } from './pseudoLocale'

const SOURCE_LANGUAGE = 'fr'
const CATALOG_DELAY_MS = 3000

// null: no catalog, and an answer that comes too late is ignored
function loadCatalog(loader) {
  if (!loader) {
    return Promise.resolve(null)
  }
  let timer
  const tooLate = new Promise((resolve) => {
    timer = setTimeout(() => resolve(null), CATALOG_DELAY_MS)
  })
  const answer = Promise.resolve().then(loader).catch(() => null)
  return Promise.race([answer, tooLate]).finally(() => clearTimeout(timer))
}

const catalogPath = (locale, name) => `/resources/lang/${locale}/${name}.json`

export async function loadLocale(i18n, locale, loaders) {
  if (locale === SOURCE_LANGUAGE) {
    return
  }
  const messages = await loadCatalog(loaders[catalogPath(locale, 'site')])
  if (messages) {
    i18n.global.setLocaleMessage(locale, withoutEmptyTexts(messages))
  }
}

// { 'kado': texts, 'games/mel': texts }: the names kado.I18nMacro gives its classes
export async function loadGameTexts(locale, gameKey, loaders) {
  if (locale === SOURCE_LANGUAGE) {
    return {}
  }
  return gameCatalogs(locale, gameKey, loaders)
}

async function gameCatalogs(locale, gameKey, loaders) {
  const names = ['kado', `games/${gameKey}`]
  const catalogs = await Promise.all(names.map((name) => loadCatalog(loaders[catalogPath(locale, name)])))
  return Object.fromEntries(names.map((name, index) => [name, catalogs[index]]).filter(([, catalog]) => catalog))
}

// development only: to see on the screen the texts of a game that cannot be translated
export async function loadPseudoGameTexts(gameKey, loaders) {
  const catalogs = await gameCatalogs(SOURCE_LANGUAGE, gameKey, loaders)
  return Object.fromEntries(Object.entries(catalogs).map(([name, catalog]) => [name, pseudoCatalog(catalog)]))
}
