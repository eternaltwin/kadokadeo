<script setup>
import { t } from '@/i18n'

const authStore = useAuthStore()
const periodStore = usePeriodStore()
const clanStore = useClanStore()
const messagesStore = useMessagesStore()
const router = useRouter()

clanStore.reload()
messagesStore.watchUnread()

const mailTitle = computed(() => {
  const parts = [
    messagesStore.unread && t('nav.unread_messages', { count: messagesStore.unread }),
    messagesStore.notificationsUnread && t('nav.unread_notifications', { count: messagesStore.notificationsUnread }),
  ].filter(Boolean)
  return parts.length ? parts.join(', ') : t('messages.title')
})

// the login page once the session is closed
const logout = async() => {
  await authStore.logout().catch(() => {})
  router.push('/login')
}
// the round buttons of the kalendrier
const button = 'block h-[21px] w-[25px] bg-[url(/gfx/kalendarButton.gif)] bg-no-repeat text-center leading-[17px] hover:bg-[url(/gfx/kalendarButtonHover.gif)]'
const rightButton = `${button} mb-1.25`
const bottomButton = `${button} mr-1.25`
</script>

<template>
  <nav class="relative mt-0.5 h-[141px] w-[201px] bg-[url(/gfx/bgKalendrier.png)] bg-no-repeat text-[0.75em]">
    <div class="absolute top-[47px] left-[18px] flex h-9 w-[140px] flex-wrap">
      <div v-for="i in periodStore.dayCount" :key="i" class="mr-1.25 mb-1.5 size-[15px] bg-[url(/gfx/kalendarPreviousDay.gif)] bg-no-repeat"></div>
      <div class="mr-1.25 mb-1.5 size-[15px] bg-[url(/gfx/kalendarPresentDay.gif)] bg-no-repeat"></div>
    </div>
    <aside>
      <p class="absolute top-2 left-3.75">
        <RouterLink :to="{ name: 'account' }" :title="$t('nav.account_preferences')">{{ authStore.user.display_name }}</RouterLink>
      </p>
      <p class="absolute top-[87px] left-[54px] h-3 w-[103px] text-center text-[0.8em] text-kado-slate-400">{{ $t('nav.period_day', { period: periodStore.period?.id, day: periodStore.dayCount + 1 }) }}</p>
    </aside>
    <ul class="absolute top-1.5 left-[166px] flex flex-col">
      <li><a href="/login"
             :class="rightButton"
             :title="$t('nav.logout')"
             @click.prevent="logout"><img src="/gfx/kalendarPreviousDay.gif" :alt="$t('nav.logout')"></a></li>
      <!-- the yellow mail of KadoKado when a message is unread -->
      <li class="relative">
        <RouterLink :class="rightButton" :to="{ name: !messagesStore.unread && messagesStore.notificationsUnread ? 'messages.notifications' : 'messages.inbox' }" :title="mailTitle">
          <img :src="messagesStore.total ? '/assets/img/gfx/icons/newMail.gif' : '/gfx/kalendarIconMail.gif'" :alt="$t('nav.mail_alt')">
        </RouterLink>
        <span v-if="messagesStore.total" class="pointer-events-none absolute -top-1 -right-1 min-w-4 rounded-full border border-white bg-kado-pink-600 px-0.5 text-center text-2xs leading-3.5 font-bold text-white">
          {{ messagesStore.total > 9 ? '9+' : messagesStore.total }}
        </span>
      </li>
      <li><RouterLink :class="rightButton" :to="{ name: 'forum.index' }" :title="$t('titles.forum')"><img src="/gfx/kalendarIconForum.gif" :alt="$t('nav.forum_alt')"></RouterLink></li>
      <li><RouterLink :class="rightButton" :to="{ name: 'profile.index' }"><img src="/gfx/kalendarIconScore.gif" :alt="$t('nav.scores_alt')"></RouterLink></li>
      <li>
        <RouterLink :class="rightButton"
                    v-if="clanStore.enabled"
                    :to="clanStore.clan ? { name: 'clans.show', params: { id: clanStore.clan.id } } : { name: 'clans.index' }"
                    :title="$t('nav.my_clan')">
          <img src="/gfx/kalendarIconClan.gif" :alt="$t('nav.clans_alt')">
        </RouterLink>
        <!-- the clans turned off in the admin -->
        <a :class="rightButton"
           v-else
           class="grayscale cursor-default"
           :title="$t('nav.my_clan_soon')">
          <img src="/gfx/kalendarIconClan.gif" :alt="$t('nav.clans_alt')">
        </a>
      </li>
    </ul>
    <ul class="absolute top-[110px] left-[7px] flex">
      <li><RouterLink :class="bottomButton" to="/" class="grayscale"><img src="/gfx/kalendarIconKado.gif" :alt="$t('nav.kado_points_alt')"></RouterLink></li>
      <li><RouterLink :class="bottomButton" :to="{ name: 'help' }"><img src="/gfx/kalendarIconHelp.gif" :alt="$t('nav.help_alt')"></RouterLink></li>
      <!-- the admin panel (Filament), outside of the SPA -->
      <li v-if="authStore.user.is_admin">
        <a :class="bottomButton"
           href="/admin"
           :title="$t('nav.administration')"
           class="text-kado-orange-500 hover:text-kado-pink-600">
          <svg viewBox="0 0 24 24"
               width="15"
               height="15"
               class="inline-block align-middle"
               :aria-label="$t('nav.admin_label')">
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
