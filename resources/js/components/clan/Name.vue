<script setup>
// the name of the clan written with the letters of the old site (/gfx/clan/typo/kword), when they all exist
const props = defineProps({
  name: { type: String, required: true },
})

const LETTERS = new Set('abcdefghiklmnopqrstuvxyz2 '.split(''))

const chars = computed(() =>
  Array.from(props.name.toLowerCase().normalize('NFD').replace(/[̀-ͯ]/g, '')),
)
const asImages = computed(() => chars.value.every((c) => LETTERS.has(c)))
</script>

<template>
  <span v-if="asImages" class="inline-flex items-end" :title="name">
    <img
      v-for="(c, index) in chars"
      :key="index"
      :src="`/gfx/clan/typo/kword/${c === ' ' ? 'space' : c}.gif`"
      :alt="c"
      class="max-w-none"
    />
  </span>
  <span v-else>{{ name }}</span>
</template>
