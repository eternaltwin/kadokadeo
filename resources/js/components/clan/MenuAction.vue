<script setup>
// a link (to) or a button of the "Actions" menu of the clan
defineProps({
  to: { type: [Object, String], default: null },
})
const emit = defineEmits(['click'])

const classes = 'mb-0.5 box-border block h-9 w-[155px] cursor-pointer overflow-hidden border-0 bg-[url(/assets/img/gfx/icons/clanInfo.gif)] bg-no-repeat py-0.5 pr-2.5 pl-0.5 text-right font-[inherit] text-sm leading-[30px] text-ellipsis whitespace-nowrap text-kado-blue no-underline hover:bg-[url(/assets/img/gfx/icons/clanInfo_hover.gif)] hover:text-kado-green-600'
</script>

<template>
  <li>
    <RouterLink v-if="to" :to="to" :class="classes">
      <slot />
    </RouterLink>
    <button v-else
            type="button"
            :class="classes"
            @click="emit('click')">
      <slot />
    </button>
  </li>
</template>
