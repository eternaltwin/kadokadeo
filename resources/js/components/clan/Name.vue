<script setup>
// the name of the clan written with the letters of the old site in the Junegull font (/gfx/clan/typo/kword, drawn by
// scripts/clan_letters.py), when they all exist
const props = defineProps({
  name: { type: String, required: true },
})

const FILES = {
  ...Object.fromEntries([...'abcdefghijklmnopqrstuvwxyz0123456789'].map((c) => [c, c])),
  ' ': 'space',
  '-': 'dash',
  '\'': 'apostrophe',
  '’': 'apostrophe',
  '.': 'dot',
  '!': 'exclamation',
  '?': 'question',
}

const chars = computed(() =>
  Array.from(props.name.toLowerCase().normalize('NFD').replace(/[̀-ͯ]/g, '')),
)
const asImages = computed(() => chars.value.every((c) => c in FILES))
</script>

<template>
  <span v-if="asImages" class="inline-flex items-end" :title="name">
    <img
      v-for="(c, index) in chars"
      :key="index"
      :src="`/gfx/clan/typo/kword/${FILES[c]}.svg`"
      :alt="c"
      class="max-w-none"
    />
  </span>
  <span v-else>{{ name }}</span>
</template>
