<script setup>
import { t } from '@/i18n'
import { intlLocale } from '@/i18n/locale'
// a private message: read (marked as read), answer, delete
const route = useRoute()
const router = useRouter()
const authStore = useAuthStore()
const messagesStore = useMessagesStore()
const { fetchMessage, deleteMessage, isLoading, error } = useMessages()

const message = ref(null)
watch(() => route.params.id, (id) => {
  fetchMessage(id).then((data) => {
    // (another message asked meanwhile: this one is not shown)
    if (id === route.params.id) {
      message.value = data
      messagesStore.reload()
    }
  }).catch(() => {}) // (shown by error)
}, { immediate: true })

const received = computed(() => message.value?.recipient.etwin_id === authStore.user?.etwin_id)
const answer = () => router.push({
  name: 'messages.new',
  query: {
    to: message.value.sender.display_name,
    subject: message.value.subject.startsWith('Re : ') ? message.value.subject : `Re : ${message.value.subject}`,
  },
})
const remove = () => {
  if (confirm(t('messages.confirm_delete'))) {
    deleteMessage(message.value.id).then(() => router.push({ name: received.value ? 'messages.inbox' : 'messages.sent' }))
  }
}
const date = (iso) => new Date(iso).toLocaleString(intlLocale(), { weekday: 'long', day: 'numeric', month: 'long', hour: '2-digit', minute: '2-digit' })
</script>

<template>
  <NavTabs
    :items="[
      { label: $t('messages.inbox'), value: 'inbox', route: { name: 'messages.inbox' } },
      { label: $t('messages.sent'), value: 'sent', route: { name: 'messages.sent' } },
      { label: $t('messages.write'), value: 'new', route: { name: 'messages.new' } },
      { label: messagesStore.notificationsUnread ? $t('messages.notifications_count', { count: messagesStore.notificationsUnread }) : $t('messages.notifications'), value: 'notifications', route: { name: 'messages.notifications' } },
    ]"
    :selected-index="received ? 0 : 1"
  />

  <div class="relative px-2 space-y-4 min-h-48">
    <Loader v-if="isLoading && !message" />
    <MessageError v-if="error">{{ error }}</MessageError>

    <template v-if="message">
      <KadoSectionTitle>{{ message.subject }}</KadoSectionTitle>
      <i18n-t v-if="received"
              keypath="messages.from_on"
              tag="p"
              class="text-sm">
        <template #sender>
          <RouterLink v-if="message.sender" :to="{ name: 'profile.show', params: { id: message.sender.etwin_id } }" class="font-bold">{{ message.sender.display_name }}</RouterLink>
          <strong v-else class="text-kado-orange-500">{{ $t('messages.system_sender') }}</strong>
        </template>
        <template #date>{{ date(message.created_at) }}</template>
      </i18n-t>
      <i18n-t v-else
              keypath="messages.to_on"
              tag="p"
              class="text-sm">
        <template #recipient>
          <RouterLink :to="{ name: 'profile.show', params: { id: message.recipient.etwin_id } }" class="font-bold">{{ message.recipient.display_name }}</RouterLink>
        </template>
        <template #date>{{ date(message.created_at) }}</template>
      </i18n-t>
      <MarktwinContent :text="message.body" class="border-2 border-white bg-white/70 p-3" />

      <div class="flex gap-2">
        <FormButton v-if="received && message.sender" size="lg" @click="answer">{{ $t('common.reply') }}</FormButton>
        <FormButton variant="pink"
                    size="lg"
                    :disabled="isLoading"
                    @click="remove">{{ $t('common.delete') }}</FormButton>
      </div>
    </template>
  </div>
</template>
