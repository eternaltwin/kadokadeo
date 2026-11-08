// ANTI CHEAT: first, before any other script can change them (see the module)
import './anticheat/natives'

import dayjs from 'dayjs'
import utc from 'dayjs/plugin/utc'
import { createPinia } from 'pinia'
import { createApp } from 'vue'
import VueLazyload from 'vue-lazyload'

import french from '../lang/fr/site.json'
import App from './App.vue'
import { registerPwa } from './composables/usePwa'
import { createAppI18n } from './i18n'
import { loadLocale } from './i18n/catalogs'
import { pageLocale } from './i18n/locale'
import router from './router'

import('./pixi-tween')

dayjs.extend(utc)

const app = createApp(App)

app.use(createPinia())
app.use(router)
const locale = pageLocale()
const i18n = createAppI18n(locale, { fr: french })
app.use(i18n)
app.use(VueLazyload, {
  error: '/gfx/achievements/error.png',
  loading: '/gfx/achievements/loading.png',
  attempt: 1,
  // the default is ['scroll', 'wheel', 'mousewheel', 'resize', 'animationend', 'transitionend']
  listenEvents: ['scroll', 'mouseup', 'resize', 'pointerup'],
})

registerPwa(router)

// the other languages are downloaded on demand, before the first render
loadLocale(i18n, locale, import.meta.glob(['/resources/lang/*/site.json', '!/resources/lang/fr/**'], { import: 'default' })).then(() => {
  app.mount('#app')
})
