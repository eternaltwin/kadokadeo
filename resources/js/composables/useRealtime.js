import { onScopeDispose, toValue, watch } from 'vue'

import { useClanStore } from '@/stores/clan'
import { useRealtimeStore } from '@/stores/realtime'

// the private channel of a player (App\Support\Realtime::user)
export const userChannel = (id) => (id ? `App.Models.User.${id}` : null)

// listens to the events of a channel while the component (or the store) lives: { 'event.name': handler }. The name can be
// a ref or a getter (null: nothing), the channel changes with it
export function useChannel(name, handlers, { isPrivate = true } = {}) {
  const realtime = useRealtimeStore()
  let stops = []
  const stop = () => {
    stops.forEach((s) => s())
    stops = []
  }

  watch(() => toValue(name), (channel) => {
    stop()
    if (channel) {
      stops = Object.entries(handlers).map(([event, handler]) => realtime.listen(channel, event, handler, { isPrivate }))
    }
  }, { immediate: true })
  onScopeDispose(stop)
}

// called when the socket connects again after a cut (the events of meanwhile were missed)
export function onRealtimeReconnect(hook) {
  const realtime = useRealtimeStore()
  onScopeDispose(realtime.onReconnect(hook))
}

// a refresh called by the polling of before: only while the realtime is not connected (no Reverb, or cut)
export function usePolling(fn, ms) {
  const realtime = useRealtimeStore()
  const id = setInterval(() => {
    if (!realtime.connected) {
      fn()
    }
  }, ms)
  onScopeDispose(() => clearInterval(id))
}

// several events in a row make one reload, a bit later (jitter: the players who receive the same event of the site do
// not all call the API at the same millisecond)
export function refetchSoon(fn, { delay = 1000, jitter = 0 } = {}) {
  let timer = null
  return (...args) => {
    clearTimeout(timer)
    timer = setTimeout(() => fn(...args), delay + Math.random() * jitter)
  }
}

// the channel of the clan of the player while a page shows it (the other clans: no channel, their members only)
const ownClanChannel = (clanId) => {
  const clanStore = useClanStore()
  const id = Number(toValue(clanId))
  return id && clanStore.clan?.id === id ? `clans.${id}` : null
}

// a page of the clan of the player: fn again when one of these parts changed (App\Events\ClanUpdated: 'clan', 'members',
// 'status', 'missions', 'history')
export function onClanUpdated(clanId, parts, fn) {
  const reload = refetchSoon(fn, { delay: 300, jitter: 700 })
  useChannel(() => ownClanChannel(clanId), {
    'clan.updated': (e) => e.parts.some((part) => parts.includes(part)) && reload(),
  })
  onRealtimeReconnect(fn)
}

// the forum of the clan of the player: fn(event) when a topic changed (App\Events\ClanForumUpdated: topic_id, deleted)
export function onClanForumUpdated(clanId, fn) {
  const reload = refetchSoon(fn, { delay: 300, jitter: 700 })
  useChannel(() => ownClanChannel(clanId), { 'clan.forum': reload })
}
