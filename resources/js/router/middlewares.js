import { registerMiddleware } from '@yazida/vue-router-middleware'

import { useAuthStore } from '@/stores/auth'

registerMiddleware('auth', ({ next }) => {
  const authStore = useAuthStore()

  if (!authStore.token) {
    return next('/login')
  }

  if (!authStore.isAuthenticated) {
    authStore.fetchUser().catch((e) => {
      if (e.response.status === 401) {
        authStore.resetToken()
        return next('/login')
      }
    }).then(() => {
      next()
    })
  } else {
    next()
  }
})
