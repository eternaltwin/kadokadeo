<script setup>
import { Tab, TabGroup, TabList, TabPanel,TabPanels } from '@headlessui/vue'

defineProps({
  items: {
    type: Array,
    required: true,
    // [{ label: 'Stats', value: 'stats', disabled: false, route: null }]
  },
})

function tabMenuLinkClasses(item) {
  const defaultClasses = 'border-solid text-center min-w-0 px-4 md:px-0 md:min-w-40 text-kado-blue font-bold block no-underline bg-repeat-x'
  const bgClasses = item.disabled ? 'grayscale cursor-not-allowed' : 'cursor-pointer hover:text-kado-cyan-800 hover:bg-[url(/gfx/bgTabmenuHover.jpg)]'
  const activeClasses = 'bg-[url(/gfx/bgTabmenuActive.jpg)] leading-[24px] bg-kado-cyan-800 border-2 border-white border-solid border-b-0 text-xl [font-variant:small-caps] tracking-normal p-0.5'
  const inactiveClasses = 'h-7 border border-kado-cyan-200 bg-[url(/gfx/bgTabmenu.jpg)]'
  return `${defaultClasses} ${bgClasses} ${item.selected ? activeClasses : inactiveClasses}`
}
</script>

<template>
  <TabGroup>
    <TabList class="flex gap-2 h-8 relative -top-[34px] -left-1">
      <Tab
        v-for="(item, index) in items"
        :key="item.value ?? index"
        as="template"
        :disabled="item.disabled"
        v-slot="{ selected }"
      >
        <slot
          name="tab"
          :item="item"
          :index="index"
          :selected="selected"
        >
          <div class="outline-none h-8 bg-kado-cyan-800 border-2 border-white border-solid border-b-0 text-xl [font-variant:small-caps] tracking-normal p-0.5" :class="item.disabled ? 'grayscale' : ''">
            <div v-if="!item.route" :class="tabMenuLinkClasses({ ...item, selected })">
              {{ item.label }}
            </div>
            <RouterLink v-else :to="item.route" :class="tabMenuLinkClasses({ ...item, selected })">
              {{ item.label }}
            </RouterLink>
          </div>
        </slot>
      </Tab>
    </TabList>

    <TabPanels>
      <TabPanel
        v-for="(item, index) in items"
        :key="item.value ?? index"
      >
        <slot
          name="panel"
          :item="item"
          :index="index"
        />
      </TabPanel>
    </TabPanels>
  </TabGroup>
</template>
