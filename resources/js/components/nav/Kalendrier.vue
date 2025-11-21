<script setup>
import { useRouter } from 'vue-router'

import { useAuthStore } from '@/stores/auth'
import { usePeriodStore } from '@/stores/period'

const authStore = useAuthStore()
const periodStore = usePeriodStore()
const router = useRouter()

const logout = () => {
  authStore.logout()
  router.push('/login')
}
</script>

<template>
  <nav id="kalendrier">
    <div class="kalendrierDays">
      <div v-for="i in periodStore.dayCount" :key="i" class="kalendrierPreviousDay"></div>
      <div class="kalendrierPresentDay"></div>
    </div>
    <aside>
      <p class="kalUser"><a href="#" @click.prevent="" title="Préférences du compte">{{ authStore.user.display_name }}</a></p>
      <p class="kalendrierText">Période {{ periodStore.period?.id }} - Jour {{ periodStore.dayCount+1 }}</p>
    </aside>
    <ul class="navKalendrierButtons">
      <li><a href="#" title="Déconnexion" @click="logout"><img src="/gfx/kalendarPreviousDay.gif" alt="logout"></a></li>
      <li><a href="#" title="Messagerie" @click="logout"><img src="/gfx/kalendarIconMail.gif" alt="mail"></a></li>
      <li><a href="#" title="Forum" @click="logout"><img src="/gfx/kalendarIconForum.gif" alt="forum"></a></li>
      <li><a href="#" title="Scores" @click="logout"><img src="/gfx/kalendarIconScore.gif" alt="scores"></a></li>
      <li><a href="#" title="Clans" @click="logout"><img src="/gfx/kalendarIconClan.gif" alt="clans"></a></li>
    </ul>
  </nav>
</template>
