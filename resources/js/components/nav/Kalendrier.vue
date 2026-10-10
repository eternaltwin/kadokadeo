<script setup>
const authStore = useAuthStore()
const periodStore = usePeriodStore()
const clanStore = useClanStore()
const router = useRouter()

clanStore.reload()

const logout = () => {
  authStore.logout()
  router.push('/login')
}
</script>

<template>
  <nav class="kalendrier">
    <div class="kalendrierDays">
      <div v-for="i in periodStore.dayCount" :key="i" class="kalendrierPreviousDay"></div>
      <div class="kalendrierPresentDay"></div>
    </div>
    <aside>
      <p class="kalUser">
        <RouterLink :to="{ name: 'account' }" title="Préférences du compte">{{ authStore.user.display_name }}</RouterLink>
      </p>
      <p class="kalendrierText">Période {{ periodStore.period?.id }} - Jour {{ periodStore.dayCount+1 }}</p>
    </aside>
    <ul class="navKalendrierButtonsRight">
      <li><RouterLink to="/" @click="logout"><img src="/gfx/kalendarPreviousDay.gif" alt="logout"></RouterLink></li>
      <li><RouterLink to="/" class="grayscale"><img src="/gfx/kalendarIconMail.gif" alt="mail"></RouterLink></li>
      <li><RouterLink to="/" class="grayscale"><img src="/gfx/kalendarIconForum.gif" alt="forum"></RouterLink></li>
      <li><RouterLink to="/" class="grayscale"><img src="/gfx/kalendarIconScore.gif" alt="scores"></RouterLink></li>
      <!-- only for the players of a clan -->
      <li v-if="clanStore.clan">
        <RouterLink :to="{ name: 'clans.show', params: { id: clanStore.clan.id } }" title="Mon clan">
          <img src="/gfx/kalendarIconClan.gif" alt="clans">
        </RouterLink>
      </li>
    </ul>
    <ul class="navKalendrierButtonsBottom">
      <li><RouterLink to="/" class="grayscale"><img src="/gfx/kalendarIconKado.gif" alt="points kado"></RouterLink></li>
      <li><RouterLink :to="{ name: 'help' }"><img src="/gfx/kalendarIconHelp.gif" alt="aide"></RouterLink></li>
      <!-- the admin panel (Filament), outside of the SPA -->
      <li v-if="authStore.user.is_admin">
        <a href="/admin" title="Administration" class="text-kado-orange hover:text-kado-pink-600">
          <svg viewBox="0 0 24 24"
               width="15"
               height="15"
               class="inline-block align-middle"
               aria-label="admin">
            <circle cx="12"
                    cy="12"
                    r="8.5"
                    fill="none"
                    stroke="currentColor"
                    stroke-width="4"
                    stroke-dasharray="3.34 3.34" />
            <circle cx="12"
                    cy="12"
                    r="5.5"
                    fill="none"
                    stroke="currentColor"
                    stroke-width="3" />
          </svg>
        </a>
      </li>
    </ul>
  </nav>
</template>
