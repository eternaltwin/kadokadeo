import { defineStore } from 'pinia'
import { ref } from 'vue'

const DURATION = 6000
const MAX = 4

// the short messages of the realtime at the top right (under the Kalendrier on a computer) (a message received, a notification, the feats of the clan): a few
// seconds, a click opens what they are about (the achievements have their banners at the bottom right)
export const useToastStore = defineStore('toast', () => {
  const toasts = ref([])
  let nextId = 0

  const dismiss = (id) => {
    toasts.value = toasts.value.filter((toast) => toast.id !== id)
  }

  // { title, text, to (a route), icon }
  const show = (toast) => {
    const id = ++nextId
    toasts.value = [...toasts.value, { ...toast, id }].slice(-MAX)
    setTimeout(() => dismiss(id), DURATION)
  }

  return {
    toasts,
    show,
    dismiss,
  }
})
