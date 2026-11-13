<script setup>
import { t } from '@/i18n'
import { intlLocale } from '@/i18n/locale'
// the bar of the games of Eternaltwin, the one of its other games (DinoRPG: ed-ui/src/components/toolBar/TopBar.vue):
// the other games (their icon, their name and their description when hovered, in another order at each visit), the
// time of the server (UTC: the daily game and the periods change at midnight UTC) and the version of the site,
// Eternaltwin, the login or the forum and the menu of the player (the drawer of the layout, below lg only: the sidebar
// is shown beside the page above; its count: the unread messages and notifications)
const emit = defineEmits(['menu'])
const authStore = useAuthStore()
const messagesStore = useMessagesStore()
const router = useRouter()
const { needsBackButton } = usePwa()

// (the names and the descriptions of DinoRPG, core/src/models/games/eternaltwinGames.mts and its locale fr.json)
const GAMES = [
  { key: 'alphabounce', name: 'AlphaBounce', link: 'https://alphabounce.eternaltwin.org/', icon: 'https://alphabounce.eternaltwin.org/favicon.ico', description: t('top_bar.games.alphabounce') },
  { key: 'dinocard', name: 'Dinocard', link: 'https://dinocard.eternaltwin.org/', icon: 'https://dinocard.eternaltwin.org/favicon.ico', description: t('top_bar.games.dinocard') },
  { key: 'dinorpg', name: 'DinoRPG', link: 'https://dinorpg.eternaltwin.org/', icon: 'https://dinorpg.eternaltwin.org/favicon.ico', description: t('top_bar.games.dinorpg') },
  { key: 'directquiz', name: 'Directquiz', link: 'https://directquiz.org/', icon: 'https://directquiz.org/images/favicon.png', description: t('top_bar.games.directquiz') },
  { key: 'emush', name: 'eMush', link: 'https://emush.eternaltwin.org/', icon: 'https://emush.eternaltwin.org/favicon.ico', description: t('top_bar.games.emush') },
  { key: 'epopotamo', name: 'ePopotamo', link: 'https://epopotamo.eternaltwin.org/', icon: 'https://epopotamo.eternaltwin.org/favicon.ico', description: t('top_bar.games.epopotamo') },
  { key: 'eternalfest', name: 'Eternalfest', link: 'https://eternalfest.net/', icon: 'https://eternalfest.net/favicon.ico', description: t('top_bar.games.eternalfest') },
  { key: 'kingdom', name: 'Eternal Kingdom', link: 'https://kingdom.eternaltwin.org/', icon: 'https://kingdom.eternaltwin.org/favicon.ico', description: t('top_bar.games.kingdom') },
  { key: 'mybrute', name: 'LaBrute', link: 'https://mybrute.eternaltwin.org/', icon: 'https://mybrute.eternaltwin.org/favicon.ico', description: t('top_bar.games.mybrute') },
  { key: 'myhordes', name: 'MyHordes', link: 'https://myhordes.eu/', icon: 'https://myhordes.eu/build/favicon/favicon.ico', description: t('top_bar.games.myhordes') },
  { key: 'neoparc', name: 'Neoparc', link: 'https://neoparc.eternaltwin.org/', icon: 'https://neoparc.eternaltwin.org/favicon.ico', description: t('top_bar.games.neoparc') },
  { key: 'pioupiouz', name: 'PiouPiouZ', link: 'https://pioupiouz.eternaltwin.org/', icon: 'https://pioupiouz.eternaltwin.org/gfx/favicon.ico', description: t('top_bar.games.pioupiouz') },
]

// another order at each visit (Fisher-Yates)
const games = [...GAMES]
for (let i = games.length - 1; i > 0; i--) {
  const j = Math.floor(Math.random() * (i + 1));
  [games[i], games[j]] = [games[j], games[i]]
}

// (package.json, given by vite.config.js)
const version = import.meta.env.VITE_APP_VERSION

const time = ref('')
const tick = () => {
  time.value = new Date().toLocaleTimeString(intlLocale(), { timeZone: 'UTC' })
}
let clock = null
onMounted(() => {
  tick()
  clock = setInterval(tick, 1000)
})
onUnmounted(() => clearInterval(clock))
</script>

<template>
  <div class="sticky top-0 z-40 flex h-etwin-bar shrink-0 items-center justify-between gap-2 bg-etwin-bar px-2 pt-[calc(0.25rem+env(safe-area-inset-top))] pb-1 text-etwin-text shadow-sm select-none">
    <button v-if="needsBackButton"
            type="button"
            class="shrink-0 cursor-pointer px-1 text-xl leading-none text-etwin-blue"
            :aria-label="$t('top_bar.back')"
            @click="router.back()">
      &lsaquo;
    </button>
    <nav class="flex h-8 min-w-0 items-center gap-2 max-md:gap-1" :aria-label="$t('top_bar.games_label')">
      <!-- on a phone: the 4 first ones -->
      <a v-for="(game, index) in games"
         :key="game.key"
         :href="game.link"
         target="_blank"
         rel="noopener noreferrer"
         class="group relative flex shrink-0 rounded p-px transition-colors hover:bg-etwin-orange focus-visible:bg-etwin-orange max-md:p-0"
         :class="{ 'max-md:hidden': index >= 4 }">
        <img :src="game.icon" :alt="game.name" class="size-4 max-md:size-3.5" />
        <span role="tooltip"
              class="pointer-events-none invisible absolute top-full left-0 z-10 mt-2 w-64 rounded border border-twinoid-600 bg-etwin-bar p-2 text-xs leading-snug font-normal text-etwin-text opacity-0 shadow-lg transition-opacity group-hover:visible group-hover:opacity-100 group-focus-visible:visible group-focus-visible:opacity-100">
          <strong class="mb-1 block text-sm text-white">{{ game.name }}</strong>
          {{ game.description }}
        </span>
      </a>
    </nav>

    <span class="flex items-baseline gap-2">
      <span class="text-etwin-blue tabular-nums" :title="$t('top_bar.server_time')">{{ time }}</span>
      <span class="text-xs text-etwin-text/60 max-md:hidden" :title="$t('top_bar.site_version')">{{ $t('top_bar.version', { version }) }}</span>
    </span>

    <div class="flex shrink-0 items-center gap-2">
      <a href="https://eternaltwin.org/"
         target="_blank"
         rel="noopener noreferrer"
         :title="$t('top_bar.eternaltwin')"
         class="rounded border border-etwin-blue/50 px-2 py-1 transition-colors hover:border-etwin-blue hover:bg-etwin-blue/5">
        <img src="https://eternaltwin.org/favicon.ico" :alt="$t('top_bar.eternaltwin')" class="size-4" />
      </a>
      <a v-if="!authStore.isAuthenticated"
         href="/login"
         class="rounded bg-etwin-green px-2 py-0.5 text-sm font-bold text-white uppercase shadow hover:no-underline">{{ $t('titles.login') }}</a>
      <RouterLink v-if="authStore.isAuthenticated"
                  :to="{ name: 'forum.index' }"
                  class="rounded border border-etwin-blue/50 px-2 py-0.5 text-sm font-bold text-etwin-blue uppercase transition-colors hover:border-etwin-blue hover:bg-etwin-blue/5 hover:no-underline">
        {{ $t('titles.forum') }}
      </RouterLink>
      <span v-if="authStore.isAuthenticated" class="relative inline-flex lg:hidden">
        <button type="button"
                class="min-w-16 cursor-pointer rounded border border-etwin-blue/50 px-2 py-0.5 text-sm font-bold text-etwin-blue uppercase transition-colors hover:border-etwin-blue hover:bg-etwin-blue/5"
                @click="emit('menu')">
          {{ $t('common.menu') }}
        </button>
        <span v-if="messagesStore.total"
              class="absolute top-0 right-0 flex h-5 min-w-5 translate-x-1/2 -translate-y-1/2 items-center justify-center rounded-full bg-etwin-green px-1.5 text-xs font-bold text-white"
              :title="$t('top_bar.unread_total', { count: messagesStore.total })">
          {{ messagesStore.total }}
        </span>
      </span>
    </div>
  </div>
</template>
