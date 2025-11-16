<script setup>
import { ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'

import { useAuthStore } from '@/stores/auth'

const authStore = useAuthStore()
const route = useRoute()
const router = useRouter()
const error = ref(null)

authStore.login(route.query?.code, route.query?.state).then(() => {
  router.push({ path: '/' })
}).catch((e) => {
  error.value = e
})
</script>

<template>
  <div class="inColumns">
    <p v-if="!error">Veuillez patienter...</p>
    <p v-else>{{ error }}</p>
  </div>
</template>
