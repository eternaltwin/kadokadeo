import { FORUM_GRAMMAR, SMILEYS, smileyUrl } from '@/marktwin/grammar'

// the renderer of @eternaltwin/marktwin (WebAssembly, ~430 KB): loaded with the first page that needs it
const renderer = shallowRef(null)
let loading = null

const escapeHtml = (text) =>
  text.replaceAll('&', '&amp;').replaceAll('<', '&lt;').replaceAll('>', '&gt;').replaceAll('"', '&quot;').replaceAll('\'', '&#39;')

// the text as it was written, while the renderer loads or when it fails
const plainHtml = (text) => escapeHtml(text).replaceAll('\n', '<br />\n')

// the WebAssembly of @eternaltwin/marktwin 0.6.0 corrupts its memory on texts with non-ASCII characters (as short as
// 31 "é", a panic, then its other calls fail): the renderer only gets ASCII, each other character as "&#233;", put back
// in its HTML (where the renderer escaped "&" into "&amp;")
const toAscii = (text) => text.replace(/[\u0080-\u{10ffff}]/gu, (char) => `&#${char.codePointAt(0)};`)
const fromAscii = (html) =>
  html.replace(/&amp;#(\d+);/g, (entity, code) => (Number(code) <= 0x10ffff ? escapeHtml(String.fromCodePoint(Number(code))) : entity))

const smileyFiles = Object.fromEntries(SMILEYS.map((smiley) => [smiley.key, smileyUrl(smiley)]))

// the icons (<span class="mkt-icon mkt-icon-kk-smile">) become the images of the smileys, the links open a new tab
const finish = (html) =>
  html
    .replace(/<span class="mkt-icon mkt-icon-([a-z0-9-]+)"><\/span>/g, (span, key) =>
      smileyFiles[key] ? `<img src="${smileyFiles[key]}" alt=":${key}:" title=":${key}:" />` : span)
    .replaceAll('<a href="', '<a target="_blank" rel="nofollow noopener noreferrer" href="')

// the messages of the forums, written in Marktwin: the HTML comes from the renderer only (it escapes the text and
// keeps the links of the grammar), so it can be shown with v-html
export function useMarktwin() {
  if (!renderer.value && !loading) {
    loading = import('@eternaltwin/marktwin').then((module) => {
      renderer.value = module.renderMarktwin
    })
  }

  const render = (text) => {
    if (!text) {
      return ''
    }
    if (!renderer.value) {
      return plainHtml(text)
    }
    try {
      return finish(fromAscii(renderer.value(FORUM_GRAMMAR, toAscii(text))))
    } catch {
      // (the renderer failing anyway: the text as it was written)
      return plainHtml(text)
    }
  }

  return { isReady: computed(() => renderer.value !== null), render }
}
