<script setup>
// writing on the forum needs the permission "forum:write" given to the site by the player on Eternaltwin: logging in
// again asks for it
</script>

<template>
  <KadoNotice variant="warning" as="p" class="mb-3 text-sm">
    <i18n-t keypath="etwin_forum.login_notice" tag="span">
      <template #link><a href="/login" class="font-bold">{{ $t('etwin_forum.login_link') }}</a></template>
    </i18n-t>
  </KadoNotice>
</template>
