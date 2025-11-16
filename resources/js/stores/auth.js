import { defineStore } from 'pinia'
import { computed, reactive, ref } from 'vue'

import { client } from '@/composables/useApi'

export const useAuthStore = defineStore('auth', () => {
  const user = ref(null)
  const stars = reactive({
    green: 0,
    orange: 0,
    red: 0,
    purple: 0,
  })
  const token = ref(localStorage.getItem('kado:token') || null)
  const greenStars = computed(() => stars.green - stars.orange)
  const orangeStars = computed(() => stars.orange - stars.red)
  const redStars = computed(() => stars.red - stars.purple)
  const purpleStars = computed(() => stars.purple)

  const isAuthenticated = computed(() => !!user.value)

  if (token.value) {
    client.defaults.headers.common['Authorization'] = `Bearer ${token.value}`
    window.Kado.token = token.value
  }

  const setUser = (u) => {
    user.value = u
    if (u && u.stars) {
      stars.green = u.stars.green_stars
      stars.orange = u.stars.orange_stars
      stars.red = u.stars.red_stars
      stars.purple = u.stars.purple_stars
    } else {
      stars.green = 0
      stars.orange = 0
      stars.red = 0
      stars.purple = 0
    }
  }

  const fetchUser = async() => {
    const { data } = await client.get('/user')
    setUser(data.data)
  }

  const login = async(code, state) => {
    // await client.get('/sanctum/csrf-cookie') // important !
    const res = await client.get('/oauth/callback', { params: { code, state } })
    token.value = res.data.token
    localStorage.setItem('kado:token', res.data.token)
    client.defaults.headers.common['Authorization'] = `Bearer ${token.value}`
    window.Kado.token = token.value
    setUser(res.data.user)
  }

  const logout = async() => {
    await client.post('/logout')
    setUser(null)
    resetToken()
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
    resetToken,
    stars,
    greenStars,
    orangeStars,
    redStars,
    purpleStars,
  }
})
