import { vi } from 'vitest'

import { client } from '@/composables/useApi'

export const ENDPOINT = 'https://fcm.googleapis.com/fcm/send/device-1'

const realAdapter = client.defaults.adapter

export function aPushBrowser({ permission = 'default', subscribed = false, answer = 'granted', supported = true } = {}) {
  const browser = { permission, timesAsked: 0, subscription: null, subscribedWith: null }
  const aSubscription = () => ({
    endpoint: ENDPOINT,
    toJSON: () => ({ endpoint: ENDPOINT, keys: { p256dh: 'key', auth: 'secret' } }),
    unsubscribe: async() => {
      browser.subscription = null
    },
  })
  browser.subscription = subscribed ? aSubscription() : null
  const pushManager = {
    getSubscription: async() => browser.subscription,
    subscribe: async(options) => {
      browser.subscribedWith = options
      browser.subscription = aSubscription()
      return browser.subscription
    },
  }
  vi.stubGlobal('Notification', {
    get permission() {
      return browser.permission
    },
    requestPermission: async() => {
      browser.timesAsked++
      browser.permission = answer
      return answer
    },
  })
  vi.stubGlobal('PushManager', supported ? function PushManager() {} : undefined)
  vi.stubGlobal('navigator', { ...navigator, serviceWorker: { getRegistration: async() => (supported ? { pushManager } : undefined) } })
  return browser
}

export function aPushServer({ down = false, testOutcome = 'delivered' } = {}) {
  const server = { devices: [], testsSent: [], down, testOutcome }
  const reply = (config, data = {}) => ({ status: 200, statusText: 'OK', headers: {}, config, data })
  client.defaults.adapter = async(config) => {
    if (server.down) {
      throw new Error('down')
    }
    const body = config.data ? JSON.parse(config.data) : {}
    if (config.method === 'post' && config.url === '/push-subscriptions') {
      server.devices = [...new Set([...server.devices, body.endpoint])]
      return reply(config)
    }
    if (config.method === 'delete' && config.url === '/push-subscriptions') {
      server.devices = server.devices.filter((endpoint) => endpoint !== body.endpoint)
      return reply(config)
    }
    if (config.method === 'post' && config.url === '/push-subscriptions/test') {
      server.testsSent.push(body.endpoint)
      return reply(config, { data: { outcome: server.testOutcome } })
    }
    throw new Error(`${config.method} ${config.url} is not faked`)
  }
  return server
}

export function forgetPushFakes() {
  client.defaults.adapter = realAdapter
  vi.unstubAllGlobals()
  delete window.Kado
}

export function turnPushOn(on = true) {
  window.Kado = { push_public_key: on ? 'BPublicKeyOfTheServerAA' : null }
}
