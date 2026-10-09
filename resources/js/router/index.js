import './middlewares'

import { createVueRouterMiddleware } from '@yazida/vue-router-middleware'
import { nextTick } from 'vue'
import { createRouter, createWebHistory } from 'vue-router'

import Account from '@/pages/account.vue'
import ClansIndex from '@/pages/clans/index.vue'
import ClansPlay from '@/pages/clans/play.vue'
import ClansShow from '@/pages/clans/show.vue'
import GamesDaily from '@/pages/games/daily.vue'
import GamesIndex from '@/pages/games/index.vue'
import GamesRanking from '@/pages/games/ranking.vue'
import GamesShow from '@/pages/games/show.vue'
import Help from '@/pages/help.vue'
import Login from '@/pages/login.vue'
import LoginCallback from '@/pages/loginCallback.vue'
import ProfileShow from '@/pages/profile/show.vue'
import RunsShow from '@/pages/runs/show.vue'

const router = createRouter({
  history: createWebHistory(),
  routes: [
    { path: '/', redirect: '/games', meta: {} },
    { path: '/login', name: 'login', component: Login, meta: {} },
    { path: '/oauth/callback', component: LoginCallback, meta: {} },
    { path: '/help', name: 'help', component: Help, meta: { middleware: ['auth'] } },
    { path: '/daily', name: 'games.daily', component: GamesDaily, meta: { middleware: ['auth'] } },
    { path: '/games', name: 'games.index', component: GamesIndex, meta: { middleware: ['auth'] } },
    { path: '/profile', name: 'profile.index', component: ProfileShow, meta: { middleware: ['auth'] } },
    { path: '/profile/:id', name: 'profile.show', component: ProfileShow, meta: { middleware: ['auth'] } },
    { path: '/games/:id', name: 'games.show', component: GamesShow, meta: { middleware: ['auth'] } },
    { path: '/games/:id/ranking', name: 'games.ranking', component: GamesRanking, meta: { middleware: ['auth'] } },
    { path: '/runs/:id', name: 'runs.show', component: RunsShow, meta: { middleware: ['auth'] } },
    { path: '/account', name: 'account', component: Account, meta: { middleware: ['auth'], title: 'Mon compte - KadoKadéo' } },
    { path: '/clans', name: 'clans.index', component: ClansIndex, meta: { middleware: ['auth'], title: 'Clans - KadoKadéo' } },
    { path: '/clans/play/:action', name: 'clans.play', component: ClansPlay, meta: { middleware: ['auth'] } },
    { path: '/clans/:id', name: 'clans.show', component: ClansShow, meta: { middleware: ['auth'], tab: 'show' } },
    { path: '/clans/:id/status', name: 'clans.status', component: ClansShow, meta: { middleware: ['auth'], tab: 'status' } },
    { path: '/clans/:id/missions', name: 'clans.missions', component: ClansShow, meta: { middleware: ['auth'], tab: 'missions' } },
    { path: '/clans/:id/members', name: 'clans.members', component: ClansShow, meta: { middleware: ['auth'], tab: 'members' } },
    { path: '/clans/:id/manage', name: 'clans.manage', component: ClansShow, meta: { middleware: ['auth'], tab: 'manage' } },
    { path: '/clans/:id/attack', name: 'clans.attack', component: ClansShow, meta: { middleware: ['auth'], tab: 'attack' } },
  ],
})

router.afterEach((to) => {
  nextTick(() => {
    document.title = to.meta.title || 'KadoKadéo'
  })
})

createVueRouterMiddleware(router)

export default router
