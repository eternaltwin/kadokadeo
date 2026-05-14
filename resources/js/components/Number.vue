<script setup>
const props = defineProps({
  value: { type: [String, Number], required: true },
  color: {
    type: String,
    default: 'green',
    validator: (value) =>
      ['green', 'orange', 'pink', 'blue', 'bigGreen', 'bigOrange', 'bigPink'].includes(value),
  },
})

const charUrls = computed(() => {
  if (typeof props.value === 'string') {
    return props.value.split('').map((c) => `/gfx/typo/${props.color}/${c == '.' ? 'dot' : c}.gif`)
  }
  const nbString = formatScore(props.value).replace(' ', '.')
  return Array.from(nbString).map((c) => `/gfx/typo/${props.color}/${c == '.' ? 'dot' : c}.gif`)
})
</script>

<template>
  <span>
    <img v-for="(charUrl, index) in charUrls" :key="index" :src="charUrl" />
  </span>
</template>
