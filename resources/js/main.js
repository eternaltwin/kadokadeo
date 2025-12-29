import dayjs from 'dayjs'
import utc from 'dayjs/plugin/utc'
import { createPinia } from 'pinia'
import { createApp } from 'vue'

import App from './App.vue'
import router from './router'

dayjs.extend(utc)

const app = createApp(App)

app.use(createPinia())
app.use(router)

app.mount('#app')
