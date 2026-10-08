<script setup>
const props = defineProps({
  value: { type: [String, Number], required: true },
  color: {
    type: String,
    default: 'green',
    validator: (value) =>
      ['green', 'orange', 'pink', 'blue', 'bigGreen', 'bigOrange', 'bigPink'].includes(value),
  },
  // height in px, defaults to the GIF height (20 for the big typos, 15 for the others)
  size: { type: Number, default: null },
})

const height = computed(() => props.size ?? (props.color.startsWith('big') ? 20 : 15))

const charUrls = computed(() => {
  const chars =
    typeof props.value === 'string' ? props.value : formatScore(props.value).replaceAll(' ', '.')
  return Array.from(chars).map((c) => `/gfx/typo/${props.color}/${c == '.' ? 'dot' : c}.svg`)
})
</script>

<template>
  <span>
    <img
      v-for="(charUrl, index) in charUrls"
      :key="index"
      class="max-w-none"
      :src="charUrl"
      :style="{ height: `${height}px` }"
    />
  </span>
</template>
