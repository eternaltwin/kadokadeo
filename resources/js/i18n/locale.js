// The language of the page, given by the server (App\Support\LocaleResolver), and the choice of the player.
const COOKIE = 'kado_locale'
const ONE_YEAR_IN_SECONDS = 365 * 24 * 60 * 60
const AUTOMATIC = 'auto'
const CHOICES = [AUTOMATIC, 'fr', 'en']
// a page without a language (the admin panel, the replay verifier) is in French; fr-FR: the format the site always had
const INTL_LOCALES = { fr: 'fr-FR' }

export const pageLocale = () => window.Kado?.locale ?? 'fr'

export const intlLocale = () => INTL_LOCALES[pageLocale()] ?? pageLocale()

const cookieChoice = () => {
  const value = document.cookie.match(new RegExp(`(?:^|; )${COOKIE}=([^;]*)`))?.[1]
  return CHOICES.includes(value) ? value : AUTOMATIC
}

export const savedChoice = (player) => {
  const accountChoice = player?.locale ?? AUTOMATIC
  return accountChoice === AUTOMATIC ? cookieChoice() : accountChoice
}

function writeCookie(choice) {
  document.cookie =
    choice === AUTOMATIC
      ? `${COOKIE}=; path=/; max-age=0; SameSite=Lax`
      : `${COOKIE}=${choice}; path=/; max-age=${ONE_YEAR_IN_SECONDS}; SameSite=Lax`
}

export async function chooseLocale(choice, { isLoggedIn, save, reload }) {
  if (isLoggedIn) {
    await save(choice)
  }
  writeCookie(choice)
  reload()
}
