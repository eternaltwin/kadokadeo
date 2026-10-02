<script setup>
import { storeToRefs } from 'pinia'
import { computed, onMounted, onUnmounted } from 'vue'

import Error from '@/components/message/Error.vue'
import Success from '@/components/message/Success.vue'
import { useAnnouncementStore } from '@/stores/announcement'

const REFRESH_INTERVAL = 5 * 60 * 1000

const announcementStore = useAnnouncementStore()
const { announcement } = storeToRefs(announcementStore)

const messageComponent = computed(() => (announcement.value?.level === 'success' ? Success : Error))

const refreshIfVisible = () => {
  if (document.visibilityState === 'visible') {
    announcementStore.fetchAnnouncement()
  }
}

let refreshTimer = null

onMounted(() => {
  announcementStore.fetchAnnouncement()
  refreshTimer = setInterval(refreshIfVisible, REFRESH_INTERVAL)
  document.addEventListener('visibilitychange', refreshIfVisible)
})

onUnmounted(() => {
  clearInterval(refreshTimer)
  document.removeEventListener('visibilitychange', refreshIfVisible)
})
</script>

<template>
  <component :is="messageComponent" v-if="announcement">
    <!-- Sanitized server-side (inline markdown, raw HTML stripped) -->
    <span v-html="announcement.html" />
  </component>
</template>
