import { fireEvent, render, screen } from '@testing-library/vue'
import { afterEach, expect, test } from 'vitest'

import { createAppI18n } from '@/i18n'
import { aPushBrowser, aPushServer, ENDPOINT, forgetPushFakes, turnPushOn } from '@/testing/push'

import PushDevice from './PushDevice.vue'

const TEXTS = {
  push: {
    title: 'Sur cet appareil',
    receive: 'Recevoir',
    unsupported: 'Pas de notifications ici',
    denied: 'Notifications bloquées',
    failed: 'Échec',
    send_test: 'Tester',
    test_sent: 'Envoyée',
    test_failed: 'Pas arrivée',
  },
}

afterEach(forgetPushFakes)

function renderPushDevice() {
  return render(PushDevice, { global: { plugins: [createAppI18n('fr', { fr: TEXTS })] } })
}

test('with the pushes off, there is nothing to choose', () => {
  turnPushOn(false)
  aPushBrowser()

  renderPushDevice()

  expect(screen.queryByText('Sur cet appareil')).toBeNull()
})

test('a player subscribes this device with a click', async() => {
  turnPushOn()
  aPushBrowser()
  const server = aPushServer()
  renderPushDevice()

  await fireEvent.click(await screen.findByLabelText('Recevoir'))

  await screen.findByRole('button', { name: 'Tester' })
  expect(server.devices).toEqual([ENDPOINT])
})

test('a player unsubscribes this device with a click', async() => {
  turnPushOn()
  const browser = aPushBrowser({ permission: 'granted', subscribed: true })
  const server = aPushServer()
  server.devices = [ENDPOINT]
  renderPushDevice()
  await screen.findByRole('button', { name: 'Tester' })

  await fireEvent.click(screen.getByLabelText('Recevoir'))

  await expect.poll(() => browser.subscription).toBeNull()
  expect(server.devices).toEqual([])
})

test('a browser without pushes says so, without a box to check', async() => {
  turnPushOn()
  aPushBrowser({ supported: false })

  renderPushDevice()

  expect(await screen.findByText('Pas de notifications ici')).toBeTruthy()
  expect(screen.queryByRole('checkbox')).toBeNull()
})

test('a permission refused says so, without a box to check', async() => {
  turnPushOn()
  aPushBrowser({ permission: 'denied' })

  renderPushDevice()

  expect(await screen.findByText('Notifications bloquées')).toBeTruthy()
  expect(screen.queryByRole('checkbox')).toBeNull()
})

test('a subscription that failed says so', async() => {
  turnPushOn()
  aPushBrowser()
  aPushServer({ down: true })
  renderPushDevice()

  await fireEvent.click(await screen.findByLabelText('Recevoir'))

  expect(await screen.findByText('Échec')).toBeTruthy()
})

test('a device not subscribed has no test to send', async() => {
  turnPushOn()
  aPushBrowser()

  renderPushDevice()

  await screen.findByLabelText('Recevoir')
  expect(screen.queryByRole('button', { name: 'Tester' })).toBeNull()
})

test('a player sends a test push and reads that it was sent', async() => {
  turnPushOn()
  aPushBrowser({ permission: 'granted', subscribed: true })
  const server = aPushServer()
  renderPushDevice()

  await fireEvent.click(await screen.findByRole('button', { name: 'Tester' }))

  expect(await screen.findByText('Envoyée')).toBeTruthy()
  expect(server.testsSent).toEqual([ENDPOINT])
})

test.each([
  ['refused by its push service', { testOutcome: 'rejected' }],
  ['that could not be sent', { down: true }],
])('a test push %s says so', async(_, server) => {
  turnPushOn()
  aPushBrowser({ permission: 'granted', subscribed: true })
  aPushServer(server)
  renderPushDevice()

  await fireEvent.click(await screen.findByRole('button', { name: 'Tester' }))

  expect(await screen.findByText('Pas arrivée')).toBeTruthy()
})
