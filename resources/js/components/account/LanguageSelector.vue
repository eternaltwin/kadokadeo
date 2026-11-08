<script setup>
// the choice of the language: only shown when the languages are on (App\Settings\SiteSettings::$i18n_enabled)
import { chooseLocale, savedChoice } from '@/i18n/locale'
import { reloadPage } from '@/i18n/reload'

const authStore = useAuthStore()
const { error, saveLocale } = useAccount()

const isShown = window.Kado.i18n_enabled
const choice = ref(savedChoice(authStore.user))

// a refused choice: useAccount shows its error, the page stays as it is
const choose = () =>
  chooseLocale(choice.value, { isLoggedIn: !!authStore.user, save: saveLocale, reload: reloadPage }).catch(() => {})
</script>

<template>
  <div v-if="isShown">
    <label>
      {{ $t('language.title') }}
      <FormSelect v-model="choice" @change="choose">
        <option value="auto">{{ $t('language.auto') }}</option>
        <option value="fr">{{ $t('language.fr') }}</option>
        <option value="en">{{ $t('language.en') }}</option>
      </FormSelect>
    </label>
    <MessageError v-if="error">{{ error }}</MessageError>
  </div>
</template>
