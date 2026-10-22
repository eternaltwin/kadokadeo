import Echo from 'laravel-echo'
import { defineStore } from 'pinia'
import Pusher from 'pusher-js'
import { ref } from 'vue'

import { client } from '@/composables/useApi'

// the realtime of the site (Reverb, App\Support\Realtime and routes/channels.php): one socket, the channels joined while
// something listens to them (useChannel). window.Kado.reverb is only set when the server broadcasts: without it nothing
// connects and the pages poll as before (usePolling)
export const useRealtimeStore = defineStore('realtime', () => {
  const config = window.Kado?.reverb ?? null
  const available = !!config
  const connected = ref(false)

  // name -> { channel, count }
  const channels = new Map()
  const reconnectHooks = new Set()
  let echo = null

  if (available) {
    const https = (config.scheme ?? window.location.protocol.replace(':', '')) === 'https'
    const port = Number(config.port ?? (window.location.port || (https ? 443 : 80)))
    echo = new Echo({
      broadcaster: 'reverb',
      Pusher,
      key: config.key,
      wsHost: config.host ?? window.location.hostname,
      wsPort: port,
      wssPort: port,
      forceTLS: https,
      enabledTransports: ['ws', 'wss'],
      // the private channels are authorized with the Sanctum token of the player (the header of the API client)
      channelAuthorization: {
        customHandler: ({ socketId, channelName }, callback) => {
          client.post('/broadcasting/auth', { socket_id: socketId, channel_name: channelName })
            .then((response) => callback(null, response.data))
            .catch((e) => callback(e, null))
        },
      },
    })

    // connected again after a cut: what happened meanwhile was missed, the pages reload what they show
    let connectedOnce = false
    echo.connector.pusher.connection.bind('state_change', ({ current }) => {
      const now = current === 'connected'
      if (now && !connected.value && connectedOnce) {
        reconnectHooks.forEach((hook) => hook())
      }
      connectedOnce ||= now
      connected.value = now
    })
  }

  // listens to ".<event>" (RealtimeEvent::broadcastAs) on a channel; returns the function that stops it. The channel is
  // left when nothing listens to it anymore
  const listen = (name, event, handler, { isPrivate = true } = {}) => {
    if (!echo) {
      return () => {}
    }
    let entry = channels.get(name)
    if (!entry) {
      entry = { channel: isPrivate ? echo.private(name) : echo.channel(name), count: 0 }
      channels.set(name, entry)
    }
    entry.count++
    entry.channel.listen(`.${event}`, handler)

    let stopped = false
    return () => {
      if (stopped) {
        return
      }
      stopped = true
      entry.channel.stopListening(`.${event}`, handler)
      if (--entry.count === 0) {
        echo.leave(name)
        channels.delete(name)
      }
    }
  }

  const onReconnect = (hook) => {
    reconnectHooks.add(hook)
    return () => reconnectHooks.delete(hook)
  }

  return {
    available,
    connected,
    listen,
    onReconnect,
  }
})
