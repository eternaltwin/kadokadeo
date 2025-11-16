<script setup>
import { useAuthStore } from '@/stores/auth'
import { usePeriodStore } from '@/stores/period'
import { useRouter } from 'vue-router'

const authStore = useAuthStore()
const periodStore = usePeriodStore()
const router = useRouter()

const days = 7
const logout = () => {
  authStore.logout()
  router.push('/login')
}
</script>

<template>
  <nav id="kalendrier">
    <div
      class="absolute top-10 left-5 w-36 grid grid-cols-7 font-bold text-lg leading-6 text-red-300"
    >
      <div v-for="i in periodStore.dayCount" :key="i">x</div>
      <div class="text-green-400">X</div>
    </div>
    <ul>
      <li id="kalUser">
        <a href="#" @click.prevent="" title="Préférences du compte">
          {{ authStore.user.display_name }}
        </a>
        (<button title="Déconnexion" @click="logout">x</button>)
      </li>
    </ul>
  </nav>
</template>
