import { flushPromises } from '@vue/test-utils'
import { afterEach, expect, test } from 'vitest'

import { aPushBrowser, aPushServer, ENDPOINT, forgetPushFakes, turnPushOn } from '@/testing/push'

import { leavePushAtLogout, pushIsOn, resyncPush, usePush } from './usePush'

afterEach(forgetPushFakes)

async function aPush() {
  const push = usePush()
  await flushPromises()
  return push
}

test('with the pushes off, there is nothing to subscribe', () => {
  turnPushOn(false)

  expect(pushIsOn()).toBe(false)
})

test('a browser without pushes says so', async() => {
  turnPushOn()
  aPushBrowser({ supported: false })

  const push = await aPush()

  expect(push.state.value).toBe('unsupported')
})

test('the permission is not asked before the player clicks', async() => {
  turnPushOn()
  const browser = aPushBrowser()

  const push = await aPush()

  expect(push.state.value).toBe('unsubscribed')
  expect(browser.timesAsked).toBe(0)
})

test('a player who subscribes gives his device to the server', async() => {
  turnPushOn()
  const browser = aPushBrowser()
  const server = aPushServer()
  const push = await aPush()

  await push.subscribe()

  expect(browser.timesAsked).toBe(1)
  expect(browser.subscribedWith.userVisibleOnly).toBe(true)
  expect(server.devices).toEqual([ENDPOINT])
  expect(push.state.value).toBe('subscribed')
})

test('a player who refuses the permission is not subscribed', async() => {
  turnPushOn()
  const browser = aPushBrowser({ answer: 'denied' })
  const server = aPushServer()
  const push = await aPush()

  await push.subscribe()

  expect(browser.subscription).toBeNull()
  expect(server.devices).toEqual([])
  expect(push.state.value).toBe('denied')
})

test('a subscription the server could not save leaves the device unsubscribed', async() => {
  turnPushOn()
  const browser = aPushBrowser()
  aPushServer({ down: true })
  const push = await aPush()

  await expect(push.subscribe()).rejects.toThrow('down')

  expect(browser.subscription).toBeNull()
  expect(push.state.value).toBe('unsubscribed')
})

test('a player who unsubscribes leaves the server and his browser', async() => {
  turnPushOn()
  const browser = aPushBrowser({ permission: 'granted', subscribed: true })
  const server = aPushServer()
  server.devices = [ENDPOINT]
  const push = await aPush()

  await push.unsubscribe()

  expect(server.devices).toEqual([])
  expect(browser.subscription).toBeNull()
  expect(push.state.value).toBe('unsubscribed')
})

test('a player who could not leave the server stays subscribed in his browser', async() => {
  turnPushOn()
  const browser = aPushBrowser({ permission: 'granted', subscribed: true })
  aPushServer({ down: true })
  const push = await aPush()

  await expect(push.unsubscribe()).rejects.toThrow('down')

  expect(browser.subscription).not.toBeNull()
  expect(push.state.value).toBe('subscribed')
})

test('a player sends a test push to this device and reads what its push service answered', async() => {
  turnPushOn()
  aPushBrowser({ permission: 'granted', subscribed: true })
  const server = aPushServer()
  const push = await aPush()

  expect(await push.sendTest()).toBe('delivered')
  expect(server.testsSent).toEqual([ENDPOINT])
})

test('a test push to a device gone from its push service shows the device unsubscribed', async() => {
  turnPushOn()
  const browser = aPushBrowser({ permission: 'granted', subscribed: true })
  aPushServer({ testOutcome: 'gone' })
  const push = await aPush()

  expect(await push.sendTest()).toBe('gone')
  expect(browser.subscription).toBeNull()
  expect(push.state.value).toBe('unsubscribed')
})

test('at each opening, the device is given again to the server', async() => {
  turnPushOn()
  aPushBrowser({ permission: 'granted', subscribed: true })
  const server = aPushServer()

  await resyncPush()

  expect(server.devices).toEqual([ENDPOINT])
})

test('a device not subscribed is not given to the server at the opening', async() => {
  turnPushOn()
  aPushBrowser({ permission: 'granted' })
  const server = aPushServer()

  await resyncPush()

  expect(server.devices).toEqual([])
})

test('at the logout, the server gets the device, then the browser leaves the pushes', async() => {
  turnPushOn()
  const browser = aPushBrowser({ permission: 'granted', subscribed: true })
  let subscribedDuringLogout = null

  const endpoint = await leavePushAtLogout(async(pushEndpoint) => {
    subscribedDuringLogout = browser.subscription !== null
    return pushEndpoint
  })

  expect(endpoint).toBe(ENDPOINT)
  expect(subscribedDuringLogout).toBe(true)
  expect(browser.subscription).toBeNull()
})

test('at the logout, the browser leaves the pushes even when they were turned off since', async() => {
  turnPushOn(false)
  const browser = aPushBrowser({ permission: 'granted', subscribed: true })

  await leavePushAtLogout(async() => {})

  expect(browser.subscription).toBeNull()
})
