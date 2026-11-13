// The translations of the site: the catalogs of resources/lang/, French when a text has none
import { createI18n } from 'vue-i18n'

const SOURCE_LANGUAGE = 'fr'

// a platform of translation can export a text not translated yet as an empty one
export const withoutEmptyTexts = (messages) =>
  Object.fromEntries(
    Object.entries(messages)
      .filter(([, value]) => value !== '')
      .map(([key, value]) => [key, typeof value === 'object' && value !== null ? withoutEmptyTexts(value) : value]),
  )

// by default, vue-i18n treats 0 as a plural in every language: in French it is a singular
function pluralRuleOf(locale) {
  const rules = new Intl.PluralRules(locale)
  return (count, branches) => (branches > 1 && rules.select(count) !== 'one' ? 1 : 0)
}

let appI18n

// for what is not a component: a store, a composable. Read when it is called, never when a module is imported
export function t(...args) {
  const { t: translate } = appI18n.global
  return translate(...args)
}

export function createAppI18n(locale, messages) {
  appI18n = createI18n({
    legacy: false,
    locale,
    fallbackLocale: SOURCE_LANGUAGE,
    // the fallback is normal for a language being translated: a console warning for each text says nothing
    fallbackWarn: false,
    messages: Object.fromEntries(
      Object.entries(messages).map(([language, catalog]) => [language, withoutEmptyTexts(catalog)]),
    ),
    pluralRules: {
      [locale]: pluralRuleOf(locale),
      [SOURCE_LANGUAGE]: pluralRuleOf(SOURCE_LANGUAGE),
    },
  })
  return appI18n
}
