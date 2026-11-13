<script setup>
import { languageChangedByLogin } from '@/i18n/locale'

const authStore = useAuthStore()
const route = useRoute()
const router = useRouter()
const error = ref(null)

authStore.login(route.query?.code, route.query?.state).then(() => {
  const nextPage = authStore.takeAfterLogin() ?? '/'
  // the language of a page comes with its load
  if (languageChangedByLogin(authStore.user)) {
    window.location.assign(router.resolve(nextPage).href)
    return
  }
  router.push(nextPage)
}).catch((e) => {
  error.value = e.response?.data?.message || e.message
})
</script>

<template>
  <div class="flex flex-wrap items-start justify-center">
    <p class="mx-2.5 my-4" v-if="!error">{{ $t('common.please_wait') }}</p>
    <MessageError v-else>{{ error }}</MessageError>
  </div>
</template>
