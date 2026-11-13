<script setup>
import { t } from '@/i18n'

defineProps({
  game: { type: Object, required: true },
})

const keyMap = {
  mouse: { image: '/gfx/controls/mouseMove.gif', title: t('games.key_mouse') },
  mouse1: { image: '/gfx/controls/mouseLeftClic.gif', title: t('games.key_left_click') },
  mouse2: { image: '', title: t('games.key_right_click') },
  space: { image: '/gfx/controls/keySpace.gif', title: t('games.key_space') },
  enter: { image: '/gfx/controls/key.gif', title: t('games.key_enter') },
  arrows: { image: '/gfx/controls/keyarrow.gif', title: t('games.key_arrows') },
  arrowup: { image: '/gfx/controls/keyUpArrow.gif', title: t('games.key_up') },
  arrowdown: { image: '/gfx/controls/keyDownArrow.gif', title: t('games.key_down') },
  arrowleft: { image: '/gfx/controls/keyLeftArrow.gif', title: t('games.key_left') },
  arrowright: { image: '/gfx/controls/keyRightArrow.gif', title: t('games.key_right') },
  shift: { image: '/gfx/controls/keyshift.gif', title: t('games.key_shift') },
  ctrl: { image: '/gfx/controls/keyctrl.gif', title: t('games.key_ctrl') },
  control: { image: '/gfx/controls/keyctrl.gif', title: t('games.key_ctrl') },
  esc: { image: '/gfx/controls/keyesc.gif', title: t('games.key_esc') },
  escape: { image: '/gfx/controls/keyesc.gif', title: t('games.key_esc') },
  p: { image: '/gfx/controls/keyp.gif', title: 'P' },
}

function getKeyView(key) {
  const mapped = keyMap[key]
  if (mapped) {
    return {
      image: mapped.image,
      title: mapped.title,
      text: mapped.title,
    }
  }

  return {
    image: '',
    title: key?.toUpperCase?.() || key,
    text: key?.toUpperCase?.() || key,
  }
}
</script>

<template>
  <KadoTable borderless
             plain-header
             rows="none"
             class="mx-auto my-2 w-71">
    <thead>
      <tr>
        <th scope="col" class="w-17.5">{{ $t('games.command') }}</th>
        <th scope="col">{{ $t('games.function') }}</th>
      </tr>
    </thead>
    <tbody>
      <tr v-for="control in game.controls" :key="control.id">
        <td>
          <template v-for="key in control.keys" :key="key">
            <img
              v-if="getKeyView(key).image"
              :src="getKeyView(key).image"
              :title="getKeyView(key).title"
              :alt="getKeyView(key).title"
              class="inline-block mr-1"
            />
            <span v-else :title="getKeyView(key).title" class="inline-block mr-1">
              {{ getKeyView(key).text }}
            </span>
          </template>
        </td>
        <td>{{ control.description }}</td>
      </tr>
    </tbody>
  </KadoTable>
</template>
