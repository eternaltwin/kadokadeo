<script setup>
import { pushIsOn, usePush } from '@/composables/usePush'

const isShown = pushIsOn()
const { state, subscribe, unsubscribe, sendTest } = usePush()
const isBusy = ref(false)
const failed = ref(false)
// 'sent' or 'failed', once a test push was sent
const testResult = ref(null)

const test = async() => {
  isBusy.value = true
  testResult.value = null
  try {
    testResult.value = await sendTest() === 'delivered' ? 'sent' : 'failed'
  } catch {
    testResult.value = 'failed'
  } finally {
    isBusy.value = false
  }
}

const choose = async(receive) => {
  isBusy.value = true
  failed.value = false
  try {
    await (receive ? subscribe() : unsubscribe())
  } catch {
    failed.value = true
  } finally {
    isBusy.value = false
  }
}
</script>

<template>
  <section v-if="isShown" class="space-y-2">
    <h2 class="normal-case">{{ $t('push.title') }}</h2>
    <p v-if="state === 'unsupported'" class="mx-0 text-sm">{{ $t('push.unsupported') }}</p>
    <p v-else-if="state === 'denied'" class="mx-0 text-sm">{{ $t('push.denied') }}</p>
    <FormCheckbox v-else
                  :model-value="state === 'subscribed'"
                  :disabled="isBusy"
                  @update:model-value="choose">
      {{ $t('push.receive') }}
    </FormCheckbox>
    <FormButton v-if="state === 'subscribed'" :disabled="isBusy" @click="test">{{ $t('push.send_test') }}</FormButton>
    <MessageSuccess v-if="testResult === 'sent'">{{ $t('push.test_sent') }}</MessageSuccess>
    <MessageError v-if="failed">{{ $t('push.failed') }}</MessageError>
    <MessageError v-else-if="testResult === 'failed'">{{ $t('push.test_failed') }}</MessageError>
  </section>
</template>
