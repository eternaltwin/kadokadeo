<script setup>
import { computed } from 'vue'
import { formatScore } from '@/composables/helpers'

const props = defineProps({
  value: { type: Number, required: true },
  color: {
    type: String,
    default: 'green',
    validator: (value) =>
      ['green', 'orange', 'pink', 'blue', 'bigGreen', 'bigOrange', 'bigRed'].includes(value),
  },
})

const charUrls = computed(() => {
  const nbString = formatScore(props.value).replace(' ', '.')
  return Array.from(nbString).map((c) => `/gfx/typo/${props.color}/${c == '.' ? 'dot' : c}.gif`)
})
</script>

<template>
  <img v-for="(charUrl, index) in charUrls" :key="index" :src="charUrl" />
</template>
