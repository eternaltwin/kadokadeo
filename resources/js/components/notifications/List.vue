<script setup>
import { notificationLink, notificationText } from '@/composables/useNotifications'
import { useChannel, userChannel } from '@/composables/useRealtime'

// the notifications of the player (the tab « Notifications » of the messages): read when the tab is opened (the new ones
// stay highlighted while it is open), deleted one by one or all
const authStore = useAuthStore()
const messagesStore = useMessagesStore()
const { get, post, del, isLoading, error } = useApi()

const notifications = ref([])
const meta = ref(null)
// the ids of the ones not read when they were shown
const fresh = ref(new Set())

const markRead = () => post('/notifications/read').then((response) => messagesStore.setCounts(response.data.data)).catch(() => {})

const load = (page = 1) =>
  get('/notifications', { params: { page } }).then((response) => {
    const list = response.data.data
    list.filter((n) => !n.read).forEach((n) => fresh.value.add(n.id))
    notifications.value = page === 1 ? list : [...notifications.value, ...list]
    meta.value = response.data.meta
    messagesStore.setCounts(response.data.unread)
    if (list.some((n) => !n.read)) {
      markRead()
    }
  })
load()
const hasNextPage = computed(() => meta.value && meta.value.current_page < meta.value.last_page)

// a new one (or the likes of a comment again): on top, read since the tab is open
useChannel(() => userChannel(authStore.user?.id), {
  'notification.received': (e) => {
    fresh.value.add(e.notification.id)
    notifications.value = [e.notification, ...notifications.value.filter((n) => n.id !== e.notification.id)]
    markRead()
  },
})

const remove = (notification) =>
  del(`/notifications/${notification.id}`).then(() => {
    notifications.value = notifications.value.filter((n) => n.id !== notification.id)
  })
const removeAll = () => {
  if (confirm('Supprimer toutes vos notifications ?')) {
    del('/notifications').then(() => {
      notifications.value = []
      meta.value = null
    })
  }
}

const date = (iso) => new Date(iso).toLocaleString('fr-FR', { day: '2-digit', month: '2-digit', year: '2-digit', hour: '2-digit', minute: '2-digit' })
</script>

<template>
  <MessageError v-if="error">{{ error }}</MessageError>
  <div class="relative overflow-x-auto">
    <Loader v-if="isLoading && !notifications.length" />
    <table class="w-full">
      <tbody>
        <tr v-if="!notifications.length && !isLoading" class="bg-kado-cyan-200">
          <td class="py-4 italic">Vous n'avez aucune notification.</td>
        </tr>
        <tr v-for="(notification, index) in notifications"
            :key="notification.id"
            :class="[index % 2 ? 'bg-white' : 'bg-kado-cyan-200', { 'font-bold': fresh.has(notification.id) }]">
          <td class="text-left">
            <RouterLink v-if="notificationLink(notification)" :to="notificationLink(notification)">{{ notificationText(notification) }}</RouterLink>
            <template v-else>{{ notificationText(notification) }}</template>
            <span v-if="notification.comment?.excerpt" class="block text-xs font-normal italic text-kado-cyan-800">« {{ notification.comment.excerpt }} »</span>
          </td>
          <td class="whitespace-nowrap text-xs font-normal">{{ date(notification.updated_at) }}</td>
          <td class="w-6">
            <button type="button"
                    class="cursor-pointer border-0 bg-transparent px-1 font-bold text-kado-pink-600"
                    title="Supprimer"
                    aria-label="Supprimer"
                    @click="remove(notification)">
              ×
            </button>
          </td>
        </tr>
      </tbody>
    </table>
  </div>
  <div class="flex justify-center gap-2">
    <FormButton v-if="hasNextPage"
                size="lg"
                :disabled="isLoading"
                @click="load(meta.current_page + 1)">Plus anciennes</FormButton>
    <FormButton v-if="notifications.length"
                variant="pink"
                size="lg"
                @click="removeAll">Tout supprimer</FormButton>
  </div>
  <p class="text-center text-xs italic">Les notifications sont supprimées automatiquement après deux mois.</p>
</template>
