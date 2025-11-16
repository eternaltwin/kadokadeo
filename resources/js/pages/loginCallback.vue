<script setup>
import { useAuthStore } from '@/stores/auth';
import { ref } from 'vue';
import { useRoute, useRouter } from 'vue-router';

const authStore = useAuthStore()
const route = useRoute()
const router = useRouter()
const error = ref(null)

authStore.login(route.query?.code, route.query?.state).then(() => {
  router.push({ path: '/' })
}).catch((e) => {
  error.value = error
})
</script>

<template>
    <div class="inColumns">
       <p v-if="!error">Veuillez patienter...</p>
       <p v-else>{{ error }}</p>
    </div>
</template>
