// The service worker of the installed site, copied to public/sw.js by vite.config.js with the time of the build at its
// top: every build is a new version for the browser (resources/js/composables/usePwa.js).
// Only the static files go through its cache: the API, the session and the pages stay on the network (a page holds the
// CSRF token), no score can be played or read offline.
const CACHE = 'kado-v1'
const OFFLINE = '/offline.html'
const MAX_ENTRIES = 500
const STATIC_FILES = /^\/(build|vendor|gamesdata|gfx|fonts|assets|icons)\//

self.addEventListener('install', (event) => {
  event.waitUntil(caches.open(CACHE).then((cache) => cache.addAll([OFFLINE, '/gfx/logoBasic.png'])).then(() => self.skipWaiting()))
})

self.addEventListener('activate', (event) => {
  event.waitUntil((async() => {
    const names = await caches.keys()
    await Promise.all(names.filter((name) => name !== CACHE).map((name) => caches.delete(name)))
    await self.registration.navigationPreload?.enable()
    await self.clients.claim()
  })())
})

async function page(event) {
  try {
    return await event.preloadResponse || await fetch(event.request)
  } catch {
    return await caches.match(OFFLINE) ?? Response.error()
  }
}

// ponytail: first in, first out, an LRU if the games played most often get pushed out
async function trim(cache) {
  const keys = await cache.keys()
  await Promise.all(keys.slice(0, Math.max(0, keys.length - MAX_ENTRIES)).map((key) => cache.delete(key)))
}

async function store(event, cache) {
  const response = await fetch(event.request)
  if (response.status === 200) {
    await cache.put(event.request, response.clone())
    await trim(cache)
  }
  return response
}

// a file named by its content (build) or its version (vendor, ?v= of the games) never changes: the cache, else the
// network; another one: the cache at once, refreshed for the next time
async function staticFile(event, immutable) {
  const cache = await caches.open(CACHE)
  const cached = await cache.match(event.request)
  if (cached && immutable) {
    return cached
  }
  const update = store(event, cache)
  if (cached) {
    event.waitUntil(update.catch(() => {}))
    return cached
  }
  return update
}

self.addEventListener('fetch', (event) => {
  const { request } = event
  const url = new URL(request.url)
  if (request.method !== 'GET' || url.origin !== location.origin) {
    return
  }
  if (request.mode === 'navigate') {
    event.respondWith(page(event))
    return
  }
  // (a Range request, the sounds: its 206 can't be cached)
  if (STATIC_FILES.test(url.pathname) && !request.headers.has('range')) {
    event.respondWith(staticFile(event, url.search !== '' || /^\/(build|vendor)\//.test(url.pathname)))
  }
})

// Not shown when a window of the site has the focus: its toast is enough. A test push is: the player is looking for it.
self.addEventListener('push', (event) => {
  event.waitUntil((async() => {
    const push = readPush(event.data)
    if (!push || (!push.test && await siteHasTheFocus())) {
      return
    }
    await self.registration.showNotification(push.title, { body: push.body, tag: push.tag, icon: '/icons/icon-192.png', data: { url: push.url } })
  })())
})

function readPush(data) {
  try {
    const push = data?.json()
    return typeof push?.title === 'string' ? push : null
  } catch {
    return null
  }
}

async function siteHasTheFocus() {
  const windows = await self.clients.matchAll({ type: 'window', includeUncontrolled: true })
  return windows.some((siteWindow) => siteWindow.focused)
}

// the page of the push, in a window of the site if one is open (only a window of this worker can be sent to a page)
self.addEventListener('notificationclick', (event) => {
  event.notification.close()
  event.waitUntil((async() => {
    const url = pageOfTheSite(event.notification.data?.url)
    const [siteWindow] = await self.clients.matchAll({ type: 'window' })
    if (!siteWindow) {
      await self.clients.openWindow(url)
      return
    }
    await siteWindow.focus()
    await siteWindow.navigate(url)
  })())
})

// never a page out of the site, whatever the payload says
function pageOfTheSite(url) {
  const page = new URL(url ?? '/', location.origin)
  return page.origin === location.origin ? page.href : `${location.origin}/`
}
