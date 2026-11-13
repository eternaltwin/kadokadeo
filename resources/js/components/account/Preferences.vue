<script setup>
import { t } from '@/i18n'

// the preferences of the player (App\Enums\UserPreference): saved as soon as one changes
const authStore = useAuthStore()
const { savePreferences, isLoading, error } = useAccount()

const groups = [
  {
    title: t('account.replay_notifications'),
    items: [
      { key: 'notify_run_comments', label: t('account.notify_run_comments') },
      { key: 'notify_comment_replies', label: t('account.notify_comment_replies') },
      { key: 'notify_comment_likes', label: t('account.notify_comment_likes') },
    ],
  },
]

const values = ref({ ...(authStore.user?.preferences ?? {}) })
watch(() => authStore.user?.preferences, (preferences) => {
  values.value = { ...(preferences ?? {}) }
})
const saved = ref(false)

const save = (key, value) => {
  saved.value = false
  values.value[key] = value
  savePreferences({ [key]: value }).then((preferences) => {
    values.value = preferences
    authStore.user.preferences = preferences
    saved.value = true
  }).catch(() => {
    values.value[key] = !value
  })
}
</script>

<template>
  <div class="space-y-4">
    <MessageError v-if="error">{{ error }}</MessageError>
    <MessageSuccess v-else-if="saved">{{ $t('account.preferences_saved') }}</MessageSuccess>

    <section v-for="group in groups" :key="group.title" class="space-y-2">
      <h2 class="normal-case">{{ group.title }}</h2>
      <FormCheckbox v-for="item in group.items"
                    :key="item.key"
                    :model-value="values[item.key] ?? true"
                    :disabled="isLoading"
                    @update:model-value="save(item.key, $event)">
        {{ item.label }}
      </FormCheckbox>
    </section>
    <p class="mx-0 text-xs italic">
      {{ $t('account.notifications_note') }}
    </p>
  </div>
</template>
