<script setup>
import { t } from '@/i18n'

// "Mon compte": the theme of the site, bought with Kado points (App\Http\Controllers\Api\ThemeController); the preferences
// of the player (components/account/Preferences.vue)
const route = useRoute()
const authStore = useAuthStore()
const tab = computed(() => route.meta.tab ?? 'account')
const tabs = [
  { label: t('account.title'), value: 'account', route: { name: 'account' } },
  { label: t('account.preferences'), value: 'preferences', route: { name: 'account.preferences' } },
]
const { fetchThemes, buyTheme, chooseTheme, isLoading, error } = useAccount()

const themes = ref([])
const notice = ref(null)
// the look of each theme: its pattern and its title bar
const previews = {
  base: { pattern: '/gfx/bgBodyPattern.jpg', title: '/gfx/bgTitleBlue.svg', panel: 'bg-kado-blue-200' },
  karbon: { pattern: '/gfx/themes/karbon/patternBG.jpg', title: '/gfx/themes/karbon/greyh2_bg.jpg', panel: 'bg-kado-slate-50' },
}

const load = () => fetchThemes().then((data) => {
  themes.value = data
}).catch(() => {}) // (shown by error)
load()

const refresh = (message) => {
  notice.value = message
  authStore.fetchUser()
  load()
}
const buy = (theme) => {
  if (confirm(t('account.confirm_buy', { theme: theme.name, price: formatScore(theme.price) }))) {
    notice.value = null
    buyTheme(theme.key).then(() => refresh(t('account.theme_bought', { theme: theme.name })))
  }
}
const use = (theme) => {
  notice.value = null
  chooseTheme(theme.key).then(() => refresh(t('account.theme_used', { theme: theme.name })))
}
</script>

<template>
  <NavTabs :items="tabs" :selected-index="tabs.findIndex((t) => t.value === tab)" />

  <div class="relative px-2 space-y-4">
    <div v-if="tab === 'preferences'" class="relative px-2 space-y-4">
      <KadoPageTitle>{{ $t('account.preferences') }}</KadoPageTitle>
      <AccountPreferences />
      <AccountLanguageSelector />
    </div>

    <KadoPageTitle>{{ $t('account.title') }}</KadoPageTitle>

    <KadoSectionTitle>{{ $t('account.theme_title') }}</KadoSectionTitle>
    <p>
      {{ $t('account.theme_intro', { site: $t('common.site_name') }) }}
    </p>
    <p>
      {{ $t('account.your_points') }}
      <strong>{{ formatScore(authStore.user?.kado_points ?? 0) }}</strong>
      <img src="/gfx/skpoint.gif" :alt="$t('account.points_alt')" class="ml-1 inline size-5" />
    </p>

    <MessageError v-if="error">{{ error }}</MessageError>
    <MessageSuccess v-else-if="notice">{{ notice }}</MessageSuccess>
    <Loader v-if="isLoading && !themes.length" />

    <div class="grid gap-4 sm:grid-cols-2">
      <div
        v-for="theme in themes"
        :key="theme.key"
        class="border-2 bg-white"
        :class="theme.active ? 'border-kado-orange-500' : 'border-kado-teal-500'"
      >
        <!-- the preview: the pattern of the background, around a panel with the title bar of the theme -->
        <div class="p-3" :style="{ background: `url(${previews[theme.key]?.pattern}) repeat` }">
          <div class="h-20 border-2 border-white" :class="previews[theme.key]?.panel">
            <div class="h-[35px] pl-10 pt-1 text-lg font-bold" :style="{ background: `url(${previews[theme.key]?.title}) no-repeat` }">
              {{ theme.name }}
            </div>
          </div>
        </div>
        <div class="flex items-center justify-between gap-2 p-2">
          <div class="text-sm">
            <template v-if="theme.price === 0">{{ $t('account.free') }}</template>
            <template v-else-if="theme.owned">{{ $t('account.bought') }}</template>
            <template v-else>
              <strong>{{ formatScore(theme.price) }}</strong>
              <img src="/gfx/skpoint.gif" :alt="$t('account.points_alt')" class="ml-1 inline size-4" />
            </template>
          </div>
          <span v-if="theme.active" class="font-bold text-kado-orange-500">{{ $t('account.current_theme') }}</span>
          <FormButton v-else-if="theme.owned" size="lg" @click="use(theme)">{{ $t('account.use') }}</FormButton>
          <FormButton v-else
                      size="lg"
                      variant="pink"
                      :disabled="(authStore.user?.kado_points ?? 0) < theme.price"
                      :title="(authStore.user?.kado_points ?? 0) < theme.price ? $t('account.not_enough_points') : ''"
                      @click="buy(theme)">{{ $t('account.buy') }}</FormButton>
        </div>
      </div>
    </div>
  </div>
</template>
