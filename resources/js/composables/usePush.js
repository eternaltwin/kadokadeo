import { shallowRef } from 'vue'

import { client } from './useApi'

// The permission of the browser is only asked on a click of the player: a refusal is final.

export function pushIsOn() {
  return Boolean(window.Kado?.push_public_key)
}

// (no worker in development without VITE_PWA_DEV: no pushes either)
async function pushManager() {
  if (typeof PushManager === 'undefined' || typeof Notification === 'undefined') {
    return null
  }
  const registration = await navigator.serviceWorker?.getRegistration()
  return registration?.pushManager ?? null
}

async function currentSubscription() {
  return await (await pushManager())?.getSubscription() ?? null
}

// (a key in base64url: its bytes, taken by every browser)
function bytesOf(base64url) {
  return Uint8Array.from(atob(base64url.replace(/-/g, '+').replace(/_/g, '/')), (character) => character.charCodeAt(0))
}

const giveToServer = (subscription) => client.post('/push-subscriptions', subscription.toJSON())

// 'unsupported' (an iPhone: only once the site is installed), 'denied', 'subscribed' or 'unsubscribed'
export function usePush() {
  const state = shallowRef('unsupported')

  async function refresh() {
    const manager = pushIsOn() ? await pushManager() : null
    if (!manager) {
      state.value = 'unsupported'
    } else if (Notification.permission === 'denied') {
      state.value = 'denied'
    } else {
      state.value = await manager.getSubscription() ? 'subscribed' : 'unsubscribed'
    }
  }

  // on a click only
  async function subscribe() {
    try {
      if (await Notification.requestPermission() !== 'granted') {
        return
      }
      const subscription = await (await pushManager()).subscribe({ userVisibleOnly: true, applicationServerKey: bytesOf(window.Kado.push_public_key) })
      await giveToServer(subscription).catch(async(error) => {
        await subscription.unsubscribe()
        throw error
      })
    } finally {
      await refresh()
    }
  }

  async function unsubscribe() {
    const subscription = await currentSubscription()
    try {
      if (subscription) {
        await client.delete('/push-subscriptions', { data: { endpoint: subscription.endpoint } })
        await subscription.unsubscribe()
      }
    } finally {
      await refresh()
    }
  }

  // what its push service answered: 'delivered', 'gone', 'retry' or 'rejected'
  async function sendTest() {
    const subscription = await currentSubscription()
    const response = await client.post('/push-subscriptions/test', { endpoint: subscription?.endpoint })
    const { outcome } = response.data.data
    if (outcome === 'gone') {
      await subscription.unsubscribe()
      await refresh()
    }
    return outcome
  }

  refresh()

  return { state, subscribe, unsubscribe, sendTest }
}

// the browser may change the address of its subscription without a word: given again at each opening
export async function resyncPush() {
  const subscription = pushIsOn() ? await currentSubscription() : null
  if (subscription && Notification.permission === 'granted') {
    await giveToServer(subscription)
  }
}

// A device shared by two players: the next one is not subscribed without his click. The server forgets the device with
// the logout (logoutOnServer gets its address), then the browser (even with the pushes turned off since).
export async function leavePushAtLogout(logoutOnServer) {
  const subscription = await currentSubscription().catch(() => null)
  try {
    return await logoutOnServer(subscription?.endpoint ?? null)
  } finally {
    await subscription?.unsubscribe().catch(() => {})
  }
}
