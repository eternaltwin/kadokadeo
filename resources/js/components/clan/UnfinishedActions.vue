<script setup>
import { t } from '@/i18n'
import { intlLocale } from '@/i18n/locale'
// the clan runs begun by the player and never ended (the page closed during the run...): "Annuler la partie" when it can
// really not be finished
const props = defineProps({
  actions: { type: Array, required: true },
})
const emit = defineEmits(['updated'])

const { cancelAction, error } = useClans()

const cancel = (action) => {
  if (confirm(t('clan_unfinished_actions.confirm_cancel', { game: action.game.name }))) {
    cancelAction(action.id).then(() => emit('updated'))
  }
}
</script>

<template>
  <KadoNotice v-if="props.actions.length" variant="warning" class="mb-4 space-y-1 text-kado-orange-700">
    <MessageError v-if="error">{{ error }}</MessageError>
    <div v-for="action in props.actions" :key="action.id" class="flex flex-wrap items-center gap-2">
      <strong>{{ action.label }}</strong>
      <span v-if="action.target">{{ $t('clan_unfinished_actions.started_with_target', { game: action.game.name, target: action.target, date: new Date(action.started_at).toLocaleString(intlLocale()) }) }}</span>
      <span v-else>{{ $t('clan_unfinished_actions.started', { game: action.game.name, date: new Date(action.started_at).toLocaleString(intlLocale()) }) }}</span>
      <FormButton variant="pink" size="sm" @click="cancel(action)">{{ $t('clan_unfinished_actions.cancel') }}</FormButton>
      <span v-if="action.blocks" class="w-full text-xs">{{ $t('clan_unfinished_actions.blocks') }}</span>
    </div>
    <p class="text-xs">{{ $t('clan_unfinished_actions.help') }}</p>
  </KadoNotice>
</template>
