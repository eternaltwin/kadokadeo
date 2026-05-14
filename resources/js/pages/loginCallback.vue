<script setup>
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
    <MessageError v-else>{{ error }}</MessageError>
  </div>
</template>
