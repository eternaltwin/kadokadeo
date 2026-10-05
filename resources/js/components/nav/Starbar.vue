<script setup>
const authStore = useAuthStore()
</script>

<template>
  <aside class="h-fit topBar transform -translate-y-0 absolute bottom-0 w-full max-w-[424px]">
    <ul class="flex justify-between items-center -my-1.5 flex-wrap gap-2">
      <li class="flex gap-2">
        <img src="/gfx/topBarPointsKado.png" alt="Points Kado" />
        <Number :value="authStore.user.kado_points ?? 0" color="bigGreen" />
      </li>
      <li class="flex gap-1 items-center">
        <img src="/gfx/topBarGreenStar.png" alt="Green Star" />
        <Number :value="authStore.greenStars" color="bigGreen" />
      </li>
      <li class="flex gap-1 items-center">
        <img src="/gfx/topBarOrangeStar.png" alt="Orange Star" />
        <Number :value="authStore.orangeStars" color="bigGreen" />
      </li>
      <li class="flex gap-1 items-center">
        <img src="/gfx/topBarRedStar.png" alt="Red Star" />
        <Number :value="authStore.redStars" color="bigGreen" />
      </li>
    </ul>
  </aside>
</template>

<style scoped>
.topBar {
  border-style: solid;
  border-width: 10px 20px 15px 20px;
  border-image-source: url("/gfx/bgTopBarInfo.png");
  border-image-slice: 10 20 15 20 fill;
  border-image-repeat: stretch;

  --tw-translate-y: calc(1/2 * 100% - 6px);
}
</style>
