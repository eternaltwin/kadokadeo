<script setup>
// a number of the "Infos" menu of the clan, with its icon
defineProps({
  icon: { type: String, required: true },
})
</script>

<template>
  <li class="flex h-[30px] items-center justify-end gap-1.5 border-b border-solid border-white pr-1 pl-[27px]">
    <slot />
    <img :src="icon" alt="" class="w-5 max-w-none" />
  </li>
</template>
