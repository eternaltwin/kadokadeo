// stores/auth.ts
import { defineStore } from 'pinia'

import { client } from '@/composables/useApi'
import { computed, ref } from 'vue'

export const useAuthStore = defineStore('auth', () => {
  const user = ref(null)
  const token = ref(localStorage.getItem('kado:token') || null)

  const isAuthenticated = computed(() => !!user.value)

  if (token.value) {
    client.defaults.headers.common['Authorization'] = `Bearer ${token.value}`
    window.Kado.token = token.value
  }

  const setUser = (u) => {
    user.value = u
  }

  const fetchUser = async () => {
    const { data } = await client.get('/user')
    setUser(data.data)
  }

  const login = async (code, state) => {
    // await client.get('/sanctum/csrf-cookie') // important !
    const res = await client.get('/oauth/callback', { params: { code, state } })
    token.value = res.data.token
    localStorage.setItem('kado:token', res.data.token)
    client.defaults.headers.common['Authorization'] = `Bearer ${token.value}`
    window.Kado.token = token.value
    setUser(res.data.user)
  }

  const logout = async () => {
    await client.post('/logout')
    setUser(null)
    resetToken()
  }
  const updateInfos = async (updates) => {
    const userRes = await api.put('/account', updates)
    setUser(userRes.data.data)
    return userRes
  }

  const resetToken = () => {
    localStorage.removeItem('kado:token')
    client.defaults.headers.common['Authorization'] = null
    token.value = null
    window.Kado.token = null
  }

  return {
    user,
    token,
    isAuthenticated,
    fetchUser,
    login,
    logout,
    setUser,
    updateInfos,
    resetToken,
  }
})
